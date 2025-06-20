import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../services/import_export_service.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';
import '../widgets/loading_widget.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  late ImportExportService _importExportService;

  // State variables
  FilePreview? _filePreview;
  String? _fileName;
  bool _isLoading = false;
  bool _isImporting = false;
  double _importProgress = 0.0;
  ImportResult? _importResult;

  // Mapping state
  Map<String, String> _columnMapping = {};
  List<ImportMapping> _savedMappings = [];
  String _selectedMappingId = '';

  // Available app fields for mapping
  final Map<String, String> _appFields = {
    'date': 'Date *',
    'amount': 'Amount *',
    'description': 'Description',
    'category': 'Category',
  };

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() {
    final expenseService = Provider.of<ExpenseService>(context, listen: false);
    final categoryService =
        Provider.of<CategoryService>(context, listen: false);
    _importExportService = ImportExportService(expenseService, categoryService);
    _loadSavedMappings();
  }

  Future<void> _loadSavedMappings() async {
    try {
      final mappings = await _importExportService.getImportMappings();
      setState(() {
        _savedMappings = mappings;
      });
    } catch (e) {
      debugPrint('Error loading saved mappings: $e');
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final preview = await _importExportService.pickAndPreviewFile();
      if (preview != null) {
        // We need to get the file bytes somehow - let me modify this
        // For now, let's store the preview and handle file bytes in the service
        setState(() {
          _filePreview = preview;
          _fileName = preview.fileName;
          // Reset mapping when new file is selected
          _columnMapping.clear();
          _importResult = null;
        });
      }
    } catch (e) {
      _showErrorDialog('File Selection Error', e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyMapping(ImportMapping mapping) {
    setState(() {
      _columnMapping = Map.from(mapping.columnMapping);
      _selectedMappingId = mapping.id;
    });
  }

  Future<void> _saveMapping() async {
    if (_columnMapping.isEmpty) {
      _showErrorDialog('Error', 'Please configure column mapping first');
      return;
    }

    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Save Mapping Preset',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Preset Name',
            hintText: 'e.g., Bank Statement Format',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _importExportService.saveImportMapping(result, _columnMapping);
        await _loadSavedMappings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mapping preset "$result" saved successfully'),
              backgroundColor: const Color(0xFF40916C),
            ),
          );
        }
      } catch (e) {
        _showErrorDialog('Error', 'Failed to save mapping preset: $e');
      }
    }
  }

  Future<void> _startImport() async {
    if (_fileName == null) {
      _showErrorDialog('Error', 'Please select a file first');
      return;
    }

    if (!_columnMapping.containsKey('date') ||
        !_columnMapping.containsKey('amount')) {
      _showErrorDialog('Error', 'Date and Amount columns are required');
      return;
    }

    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
      _importResult = null;
    });

    try {
      final result = await _importExportService.importExpenses(
        columnMapping: _columnMapping,
        onProgress: (progress) {
          setState(() {
            _importProgress = progress;
          });
        },
      );

      setState(() {
        _importResult = result;
      });

      _showImportResultDialog(result);
    } catch (e) {
      _showErrorDialog('Import Error', e.toString());
    } finally {
      setState(() {
        _isImporting = false;
      });
    }
  }

  void _showImportResultDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Import Complete',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total rows processed: ${result.totalRows}'),
            Text(
              'Successfully imported: ${result.successfulImports}',
              style: const TextStyle(color: Color(0xFF40916C)),
            ),
            if (result.failedImports > 0)
              Text(
                'Failed imports: ${result.failedImports}',
                style: const TextStyle(color: Colors.red),
              ),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Errors:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              ...result.errors.take(5).map((error) => Text(
                  'Row ${error.rowIndex}: ${error.error}',
                  style: const TextStyle(fontSize: 12, color: Colors.red))),
              if (result.errors.length > 5)
                Text('... and ${result.errors.length - 5} more errors'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (result.successfulImports > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to expenses screen
              },
              child: const Text('View Expenses'),
            ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Import Expenses',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File Selection Section
                  _buildFileSelectionSection(),

                  if (_filePreview != null) ...[
                    const SizedBox(height: 32),
                    _buildPreviewSection(),
                    const SizedBox(height: 32),
                    _buildMappingSection(),
                    const SizedBox(height: 32),
                    _buildImportSection(),
                  ],

                  if (_importResult != null) ...[
                    const SizedBox(height: 32),
                    _buildResultSection(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFileSelectionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.cloud_upload,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Select CSV or Excel File',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your bank statements or expense data\nSupported formats: CSV, XLSX, XLS (max 10MB)',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(CupertinoIcons.folder, color: Colors.white),
            label: Text(
              'Browse Files',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B4332),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF40916C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.doc_checkmark,
                    color: Color(0xFF40916C),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fileName!,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1B4332),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_filePreview == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'File Preview',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: _filePreview!.headers
                  .map(
                    (header) => DataColumn(
                      label: Text(
                        header,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                  .toList(),
              rows: _filePreview!.rows
                  .map(
                    (row) => DataRow(
                      cells: row
                          .map(
                            (cell) => DataCell(Text(cell,
                                style: GoogleFonts.inter(fontSize: 12))),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Showing first ${_filePreview!.rows.length} rows',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMappingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Column Mapping',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            if (_savedMappings.isNotEmpty)
              PopupMenuButton<ImportMapping>(
                icon: const Icon(CupertinoIcons.bookmark),
                tooltip: 'Load Saved Mapping',
                onSelected: _applyMapping,
                itemBuilder: (context) => _savedMappings
                    .map(
                      (mapping) => PopupMenuItem(
                        value: mapping,
                        child: Text(mapping.name),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _saveMapping,
              icon: const Icon(CupertinoIcons.bookmark_fill),
              tooltip: 'Save Mapping',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Map your file columns to expense fields. * indicates required fields.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        ..._appFields.entries
            .map(
              (entry) => _buildMappingRow(entry.key, entry.value),
            )
            .toList(),
      ],
    );
  }

  Widget _buildMappingRow(String appField, String appFieldLabel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              appFieldLabel,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: appFieldLabel.contains('*')
                    ? const Color(0xFF1B4332)
                    : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<String>(
              value: _columnMapping[appField],
              hint: const Text('Select column'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('None'),
                ),
                ..._filePreview!.headers
                    .map(
                      (header) => DropdownMenuItem<String>(
                        value: header,
                        child: Text(header),
                      ),
                    )
                    .toList(),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == null) {
                    _columnMapping.remove(appField);
                  } else {
                    _columnMapping[appField] = value;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportSection() {
    final canImport = _columnMapping.containsKey('date') &&
        _columnMapping.containsKey('amount');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import Settings',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (_isImporting) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF40916C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  'Importing expenses...',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _importProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF40916C)),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_importProgress * 100).toInt()}% complete',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
              ],
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canImport ? _startImport : null,
              icon: const Icon(CupertinoIcons.cloud_download,
                  color: Colors.white),
              label: Text(
                'Import Expenses',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canImport ? const Color(0xFF1B4332) : Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (!canImport) ...[
            const SizedBox(height: 8),
            Text(
              'Please map Date and Amount columns to proceed',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildResultSection() {
    if (_importResult == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _importResult!.failedImports > 0
            ? Colors.orange.withOpacity(0.1)
            : const Color(0xFF40916C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _importResult!.failedImports > 0
              ? Colors.orange
              : const Color(0xFF40916C),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Import Summary',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text('Total rows: ${_importResult!.totalRows}'),
          Text(
            'Successfully imported: ${_importResult!.successfulImports}',
            style: const TextStyle(color: Color(0xFF40916C)),
          ),
          if (_importResult!.failedImports > 0)
            Text(
              'Failed imports: ${_importResult!.failedImports}',
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}
