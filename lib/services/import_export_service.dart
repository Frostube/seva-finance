import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';
import '../models/expense_category.dart';
import 'package:uuid/uuid.dart';
import 'package:universal_html/html.dart' as html;

// Import mapping preset model
class ImportMapping {
  final String id;
  final String name;
  final Map<String, String> columnMapping; // CSV column -> app field
  final DateTime createdAt;

  ImportMapping({
    required this.id,
    required this.name,
    required this.columnMapping,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'columnMapping': columnMapping,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ImportMapping.fromJson(Map<String, dynamic> json) => ImportMapping(
        id: json['id'],
        name: json['name'],
        columnMapping: Map<String, String>.from(json['columnMapping']),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

// Import result model
class ImportResult {
  final int totalRows;
  final int successfulImports;
  final int failedImports;
  final List<ImportError> errors;
  final List<Expense> importedExpenses;

  ImportResult({
    required this.totalRows,
    required this.successfulImports,
    required this.failedImports,
    required this.errors,
    required this.importedExpenses,
  });
}

// Import error model
class ImportError {
  final int rowIndex;
  final String error;
  final Map<String, dynamic> rowData;

  ImportError({
    required this.rowIndex,
    required this.error,
    required this.rowData,
  });
}

// File preview model
class FilePreview {
  final List<List<String>> rows;
  final List<String> headers;
  final String fileName;
  final String fileType;

  FilePreview({
    required this.rows,
    required this.headers,
    required this.fileName,
    required this.fileType,
  });
}

class ImportExportService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ExpenseService _expenseService;
  final CategoryService _categoryService;
  final _uuid = const Uuid();

  // Rate limiting
  static const int _maxImportsPerDay = 5;
  static const int _maxExportsPerHour = 3;
  static const int _maxFileSizeMB = 10;

  // Store current file data
  Uint8List? _currentFileBytes;
  String? _currentFileName;

  ImportExportService(this._expenseService, this._categoryService);

  String? get _userId => _auth.currentUser?.uid;

  // ============ IMPORT FUNCTIONALITY ============

  /// Pick and preview a CSV/Excel file
  Future<FilePreview?> pickAndPreviewFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        final fileName = file.name;
        final fileBytes = file.bytes!;

        // Store file data for later import
        _currentFileBytes = fileBytes;
        _currentFileName = fileName;

        // Check file size
        if (fileBytes.length > _maxFileSizeMB * 1024 * 1024) {
          throw Exception('File size exceeds ${_maxFileSizeMB}MB limit');
        }

        final fileType = fileName.split('.').last.toLowerCase();

        if (fileType == 'csv') {
          return _previewCsvFile(fileBytes, fileName);
        } else if (fileType == 'xlsx' || fileType == 'xls') {
          return _previewExcelFile(fileBytes, fileName);
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      rethrow;
    }
    return null;
  }

  /// Preview CSV file content
  FilePreview _previewCsvFile(Uint8List fileBytes, String fileName) {
    final csvString = utf8.decode(fileBytes);
    final csvData = const CsvToListConverter().convert(csvString);

    if (csvData.isEmpty) {
      throw Exception('CSV file is empty');
    }

    final headers = csvData.first.map((e) => e.toString()).toList();
    final rows = csvData
        .skip(1)
        .take(10)
        .map((row) => row.map((e) => e.toString()).toList())
        .toList();

    return FilePreview(
      rows: rows,
      headers: headers,
      fileName: fileName,
      fileType: 'csv',
    );
  }

  /// Preview Excel file content
  FilePreview _previewExcelFile(Uint8List fileBytes, String fileName) {
    final excel = Excel.decodeBytes(fileBytes);
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;

    if (sheet.rows.isEmpty) {
      throw Exception('Excel file is empty');
    }

    final headers =
        sheet.rows.first.map((cell) => cell?.value?.toString() ?? '').toList();

    final rows = sheet.rows
        .skip(1)
        .take(10)
        .map((row) => row.map((cell) => cell?.value?.toString() ?? '').toList())
        .toList();

    return FilePreview(
      rows: rows,
      headers: headers,
      fileName: fileName,
      fileType: 'excel',
    );
  }

  /// Import expenses from file with mapping
  Future<ImportResult> importExpenses({
    required Map<String, String> columnMapping,
    Function(double)? onProgress,
  }) async {
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    // Check rate limits
    await _checkImportRateLimit();

    if (_currentFileBytes == null || _currentFileName == null) {
      throw Exception('No file selected for import');
    }

    final fileType = _currentFileName!.split('.').last.toLowerCase();
    List<List<String>> allRows;

    if (fileType == 'csv') {
      final csvString = utf8.decode(_currentFileBytes!);
      final csvData = const CsvToListConverter().convert(csvString);
      allRows = csvData
          .skip(1)
          .map((row) => row.map((e) => e.toString()).toList())
          .toList();
    } else {
      final excel = Excel.decodeBytes(_currentFileBytes!);
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;
      allRows = sheet.rows
          .skip(1)
          .map((row) =>
              row.map((cell) => cell?.value?.toString() ?? '').toList())
          .toList();
    }

    final errors = <ImportError>[];
    final importedExpenses = <Expense>[];
    final totalRows = allRows.length;
    int processedRows = 0;

    // Get file headers for mapping
    final headers = fileType == 'csv'
        ? const CsvToListConverter()
            .convert(utf8.decode(_currentFileBytes!))
            .first
            .map((e) => e.toString())
            .toList()
        : Excel.decodeBytes(_currentFileBytes!)
            .tables
            .values
            .first
            .rows
            .first
            .map((cell) => cell?.value?.toString() ?? '')
            .toList();

    // Process rows in batches
    const batchSize = 100;
    for (int i = 0; i < allRows.length; i += batchSize) {
      final batch = allRows.skip(i).take(batchSize).toList();
      final batchResults =
          await _processBatch(batch, headers, columnMapping, i);

      errors.addAll(batchResults['errors'] as List<ImportError>);
      importedExpenses.addAll(batchResults['expenses'] as List<Expense>);

      processedRows += batch.length;
      onProgress?.call(processedRows / totalRows);
    }

    // Record import activity
    await _recordImportActivity();

    return ImportResult(
      totalRows: totalRows,
      successfulImports: importedExpenses.length,
      failedImports: errors.length,
      errors: errors,
      importedExpenses: importedExpenses,
    );
  }

  /// Process a batch of rows
  Future<Map<String, dynamic>> _processBatch(
    List<List<String>> batch,
    List<String> headers,
    Map<String, String> columnMapping,
    int startIndex,
  ) async {
    final errors = <ImportError>[];
    final expenses = <Expense>[];

    for (int i = 0; i < batch.length; i++) {
      final rowIndex = startIndex + i + 1; // +1 for header row
      final row = batch[i];

      try {
        final expense = await _parseRowToExpense(row, headers, columnMapping);
        if (expense != null) {
          expenses.add(expense);
        }
      } catch (e) {
        errors.add(ImportError(
          rowIndex: rowIndex,
          error: e.toString(),
          rowData: Map.fromIterables(headers, row),
        ));
      }
    }

    // Batch write to Firestore
    if (expenses.isNotEmpty) {
      await _batchWriteExpenses(expenses);
    }

    return {
      'errors': errors,
      'expenses': expenses,
    };
  }

  /// Parse a row to an Expense object
  Future<Expense?> _parseRowToExpense(
    List<String> row,
    List<String> headers,
    Map<String, String> columnMapping,
  ) async {
    final rowData = <String, String>{};
    for (int i = 0; i < headers.length && i < row.length; i++) {
      rowData[headers[i]] = row[i];
    }

    // Extract mapped fields
    final dateColumn = columnMapping['date'];
    final amountColumn = columnMapping['amount'];
    final descriptionColumn = columnMapping['description'];
    final categoryColumn = columnMapping['category'];

    if (dateColumn == null || amountColumn == null) {
      throw Exception('Date and Amount columns are required');
    }

    // Parse date
    final dateString = rowData[dateColumn]?.trim();
    if (dateString == null || dateString.isEmpty) {
      throw Exception('Date is required');
    }

    DateTime date;
    try {
      // Try multiple date formats
      final dateFormats = [
        'yyyy-MM-dd',
        'MM/dd/yyyy',
        'dd/MM/yyyy',
        'yyyy/MM/dd',
        'MM-dd-yyyy',
        'dd-MM-yyyy',
      ];

      DateTime? parsedDate;
      for (final format in dateFormats) {
        try {
          parsedDate = DateFormat(format).parse(dateString);
          break;
        } catch (e) {
          continue;
        }
      }

      if (parsedDate == null) {
        throw Exception('Invalid date format: $dateString');
      }
      date = parsedDate;
    } catch (e) {
      throw Exception('Invalid date: $dateString');
    }

    // Parse amount
    final amountString = rowData[amountColumn]?.trim();
    if (amountString == null || amountString.isEmpty) {
      throw Exception('Amount is required');
    }

    double amount;
    try {
      // Remove currency symbols and commas
      final cleanAmount =
          amountString.replaceAll(RegExp(r'[^\d.-]'), '').replaceAll(',', '');
      amount = double.parse(cleanAmount);

      // Ensure positive amount for expenses
      amount = amount.abs();
    } catch (e) {
      throw Exception('Invalid amount: $amountString');
    }

    // Get description
    final description =
        descriptionColumn != null ? rowData[descriptionColumn]?.trim() : null;

    // Handle category
    String categoryId = 'uncategorized';
    if (categoryColumn != null) {
      final categoryName = rowData[categoryColumn]?.trim();
      if (categoryName != null && categoryName.isNotEmpty) {
        categoryId = await _findOrCreateCategory(categoryName);
      }
    }

    return Expense(
      id: _uuid.v4(),
      amount: amount,
      categoryId: categoryId,
      date: date,
      note: description,
    );
  }

  /// Find existing category or create new one
  Future<String> _findOrCreateCategory(String categoryName) async {
    await _categoryService.initializationComplete;

    // Try to find existing category
    final existingCategory = _categoryService.categories
        .where((cat) => cat.name.toLowerCase() == categoryName.toLowerCase())
        .firstOrNull;

    if (existingCategory != null) {
      return existingCategory.id;
    }

    // Create new category
    try {
      final newCategory = ExpenseCategory(
        id: _uuid.v4(),
        name: categoryName,
        icon: 'help_outline',
      );

      await _categoryService.addCategory(newCategory);
      return newCategory.id;
    } catch (e) {
      debugPrint('Failed to create category: $e');
      return 'uncategorized';
    }
  }

  /// Batch write expenses to Firestore
  Future<void> _batchWriteExpenses(List<Expense> expenses) async {
    if (_userId == null) return;

    const batchSize = 300; // Firestore batch limit is 500
    for (int i = 0; i < expenses.length; i += batchSize) {
      final batch = _firestore.batch();
      final batchExpenses = expenses.skip(i).take(batchSize);

      for (final expense in batchExpenses) {
        final docRef = _firestore
            .collection('users')
            .doc(_userId)
            .collection('expenses')
            .doc(expense.id);

        batch.set(docRef, expense.toJson());
      }

      await batch.commit();
    }

    // Add to local service
    for (final expense in expenses) {
      await _expenseService.addExpense(expense);
    }
  }

  // ============ EXPORT FUNCTIONALITY ============

  /// Test method to create a simple Excel file for debugging
  Future<void> testExcelExport() async {
    try {
      debugPrint('Creating test Excel file...');

      final excel = Excel.createExcel();
      final sheet = excel['Test'];

      // Remove default sheet
      if (excel.tables.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Add test data
      sheet.cell(CellIndex.indexByString('A1')).value =
          TextCellValue('Test Header');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Value');
      sheet.cell(CellIndex.indexByString('A2')).value =
          TextCellValue('Test Data');
      sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue('123.45');

      debugPrint('Test data added to sheet');
      debugPrint('Sheet tables: ${excel.tables.keys.toList()}');
      debugPrint('Sheet max rows: ${sheet.maxRows}');

      final excelBytes = excel.encode();
      if (excelBytes == null) {
        debugPrint('ERROR: Excel encoding returned null');
        return;
      }

      debugPrint(
          'Test Excel encoded successfully, size: ${excelBytes.length} bytes');

      final bytes = Uint8List.fromList(excelBytes);
      await _saveAndDownloadFile(
        bytes,
        'test-export.xlsx',
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      debugPrint('Test Excel file saved successfully');
    } catch (e) {
      debugPrint('ERROR in test Excel export: $e');
      rethrow;
    }
  }

  /// Export expenses to CSV
  Future<String> exportToCSV({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _checkExportRateLimit();

    final expenses = await _getExpensesForExport(startDate, endDate);
    final csvData = await _convertExpensesToCSV(expenses);

    final fileName = _generateFileName('csv', startDate, endDate);
    await _saveAndDownloadFile(csvData, fileName, 'text/csv');

    await _recordExportActivity();
    return fileName;
  }

  /// Export expenses to Excel
  Future<String> exportToExcel({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await _checkExportRateLimit();

    final expenses = await _getExpensesForExport(startDate, endDate);
    final excelBytes = await _convertExpensesToExcel(expenses);

    final fileName = _generateFileName('xlsx', startDate, endDate);
    await _saveAndDownloadFile(excelBytes, fileName,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

    await _recordExportActivity();
    return fileName;
  }

  /// Get expenses for export within date range
  Future<List<Expense>> _getExpensesForExport(
      DateTime? startDate, DateTime? endDate) async {
    await _expenseService.initializationComplete;
    final allExpenses = await _expenseService.getAllExpenses();

    if (startDate == null && endDate == null) {
      return allExpenses;
    }

    return allExpenses.where((expense) {
      if (startDate != null && expense.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && expense.date.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Convert expenses to CSV format
  Future<Uint8List> _convertExpensesToCSV(List<Expense> expenses) async {
    await _categoryService.initializationComplete;

    final csvData = <List<String>>[];

    // Headers
    csvData.add(['Date', 'Description', 'Category', 'Amount']);

    // Data rows
    for (final expense in expenses) {
      final categoryName = _categoryService.getCategoryNameById(
        expense.categoryId,
        defaultName: 'Uncategorized',
      );

      csvData.add([
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.note ?? '',
        categoryName,
        expense.amount.toString(),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    return Uint8List.fromList(utf8.encode(csvString));
  }

  /// Convert expenses to Excel format
  Future<Uint8List> _convertExpensesToExcel(List<Expense> expenses) async {
    await _categoryService.initializationComplete;

    debugPrint('Starting Excel export for ${expenses.length} expenses');

    final excel = Excel.createExcel();

    // Create our sheet first
    final sheet = excel['Expenses'];

    // Remove default sheet after creating our sheet
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    debugPrint('Excel sheets after setup: ${excel.tables.keys.toList()}');

    // Headers
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Date');
    sheet.cell(CellIndex.indexByString('B1')).value =
        TextCellValue('Description');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Category');
    sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('Amount');

    debugPrint('Headers added to Excel sheet');

    // Data rows
    for (int i = 0; i < expenses.length; i++) {
      final expense = expenses[i];
      final row = i + 2; // Start from row 2 (after header)

      final categoryName = _categoryService.getCategoryNameById(
        expense.categoryId,
        defaultName: 'Uncategorized',
      );

      sheet.cell(CellIndex.indexByString('A$row')).value =
          TextCellValue(DateFormat('yyyy-MM-dd').format(expense.date));
      sheet.cell(CellIndex.indexByString('B$row')).value =
          TextCellValue(expense.note ?? '');
      sheet.cell(CellIndex.indexByString('C$row')).value =
          TextCellValue(categoryName);
      // Use TextCellValue for amount to ensure compatibility
      sheet.cell(CellIndex.indexByString('D$row')).value =
          TextCellValue(expense.amount.toStringAsFixed(2));
    }

    debugPrint('Data rows added to Excel sheet');
    debugPrint('Sheet row count: ${sheet.maxRows}');
    debugPrint('Sheet column count: ${sheet.maxColumns}');

    // Verify data is actually in the sheet
    if (sheet.maxRows <= 1) {
      debugPrint('Warning: Sheet appears to be empty or only has headers');
    }

    final excelBytes = excel.encode();
    if (excelBytes == null) {
      throw Exception('Failed to encode Excel file');
    }

    debugPrint(
        'Excel file encoded successfully, size: ${excelBytes.length} bytes');

    // Additional validation
    if (excelBytes.isEmpty) {
      throw Exception('Excel file is empty after encoding');
    }

    return Uint8List.fromList(excelBytes);
  }

  /// Generate filename for export
  String _generateFileName(
      String extension, DateTime? startDate, DateTime? endDate) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);

    String suffix = '';
    if (startDate != null && endDate != null) {
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);
      suffix = '_${startStr}_$endStr';
    } else if (startDate != null) {
      final startStr = DateFormat('yyyy-MM-dd').format(startDate);
      suffix = '_from_$startStr';
    } else if (endDate != null) {
      final endStr = DateFormat('yyyy-MM-dd').format(endDate);
      suffix = '_until_$endStr';
    }

    return 'seva-transactions-$dateStr$suffix.$extension';
  }

  /// Save and download file (web/mobile compatible)
  Future<void> _saveAndDownloadFile(
      Uint8List bytes, String fileName, String mimeType) async {
    if (kIsWeb) {
      // Web download using universal_html
      try {
        final blob = html.Blob([bytes], mimeType);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } catch (e) {
        debugPrint('Error downloading file: $e');
        rethrow;
      }
    } else {
      // Mobile save to downloads
      try {
        final directory = await getDownloadsDirectory() ??
            await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
      } catch (e) {
        debugPrint('Error saving file: $e');
        rethrow;
      }
    }
  }

  // ============ MAPPING PRESETS ============

  /// Save import mapping preset
  Future<void> saveImportMapping(
      String name, Map<String, String> columnMapping) async {
    if (_userId == null) return;

    final mapping = ImportMapping(
      id: _uuid.v4(),
      name: name,
      columnMapping: columnMapping,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('importPresets')
        .doc(mapping.id)
        .set(mapping.toJson());
  }

  /// Get saved import mapping presets
  Future<List<ImportMapping>> getImportMappings() async {
    if (_userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('importPresets')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ImportMapping.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading import mappings: $e');
      return [];
    }
  }

  /// Delete import mapping preset
  Future<void> deleteImportMapping(String mappingId) async {
    if (_userId == null) return;

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('importPresets')
        .doc(mappingId)
        .delete();
  }

  // ============ RATE LIMITING ============

  Future<void> _checkImportRateLimit() async {
    if (_userId == null) return;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('importActivity')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    if (snapshot.docs.length >= _maxImportsPerDay) {
      throw Exception('Daily import limit of $_maxImportsPerDay reached');
    }
  }

  Future<void> _checkExportRateLimit() async {
    if (_userId == null) return;

    final now = DateTime.now();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    final snapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('exportActivity')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(oneHourAgo))
        .get();

    if (snapshot.docs.length >= _maxExportsPerHour) {
      throw Exception('Hourly export limit of $_maxExportsPerHour reached');
    }
  }

  Future<void> _recordImportActivity() async {
    if (_userId == null) return;

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('importActivity')
        .add({
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _recordExportActivity() async {
    if (_userId == null) return;

    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('exportActivity')
        .add({
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
