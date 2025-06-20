import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/import_export_service.dart';
import '../services/expense_service.dart';
import '../services/category_service.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late ImportExportService _importExportService;

  // State variables
  String _selectedFormat = 'csv';
  String _selectedRange = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  // Date range options
  final Map<String, String> _dateRanges = {
    'all': 'All Time',
    'current_month': 'Current Month',
    'last_month': 'Last Month',
    'last_3_months': 'Last 3 Months',
    'last_6_months': 'Last 6 Months',
    'current_year': 'Current Year',
    'custom': 'Custom Range',
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
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case 'current_month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _startDate = lastMonth;
        _endDate = DateTime(lastMonth.year, lastMonth.month + 1, 0);
        break;
      case 'last_3_months':
        _startDate = DateTime(now.year, now.month - 3, 1);
        _endDate = now;
        break;
      case 'last_6_months':
        _startDate = DateTime(now.year, now.month - 6, 1);
        _endDate = now;
        break;
      case 'current_year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
        break;
      case 'all':
      default:
        _startDate = null;
        _endDate = null;
        break;
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      String fileName;
      if (_selectedFormat == 'csv') {
        fileName = await _importExportService.exportToCSV(
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        fileName = await _importExportService.exportToExcel(
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      if (mounted) {
        _showSuccessDialog(fileName);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Export Error', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showSuccessDialog(String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Export Complete',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: Color(0xFF40916C),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Your export is ready!',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'File: $fileName',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your Downloads folder',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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

  Future<void> _testExcelExport() async {
    setState(() {
      _isExporting = true;
    });

    try {
      await _importExportService.testExcelExport();

      if (mounted) {
        _showSuccessDialog('test-export.xlsx');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Test Export Error', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
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
          'Export Expenses',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Format Selection
            _buildFormatSection(),

            const SizedBox(height: 32),

            // Date Range Selection
            _buildDateRangeSection(),

            const SizedBox(height: 32),

            // Export Preview
            _buildPreviewSection(),

            const SizedBox(height: 32),

            // Export Button
            _buildExportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Format',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFormatOption(
                'csv',
                'CSV',
                'Comma-separated values\nCompatible with Excel, Google Sheets',
                CupertinoIcons.doc_text,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFormatOption(
                'xlsx',
                'Excel',
                'Microsoft Excel format\nAdvanced formatting support',
                CupertinoIcons.table,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatOption(
      String value, String title, String description, IconData icon) {
    final isSelected = _selectedFormat == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFormat = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1B4332).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF1B4332) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? const Color(0xFF1B4332) : Colors.grey[600],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF1B4332) : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedRange,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: _dateRanges.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRange = value!;
              _updateDateRange();
            });
          },
        ),
        if (_selectedRange == 'custom') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  'Start Date',
                  _startDate,
                  _selectStartDate,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDateSelector(
                  'End Date',
                  _endDate,
                  _selectEndDate,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? DateFormat('MMM dd, yyyy').format(date)
                      : 'Select date',
                  style: GoogleFonts.inter(
                    color: date != null ? Colors.black : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    String rangeText = 'All expenses';

    if (_selectedRange == 'custom' && _startDate != null && _endDate != null) {
      rangeText =
          '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}';
    } else if (_selectedRange != 'all') {
      rangeText = _dateRanges[_selectedRange]!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Preview',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildPreviewRow('Format', _selectedFormat.toUpperCase()),
          _buildPreviewRow('Date Range', rangeText),
          _buildPreviewRow('Columns', 'Date, Description, Category, Amount'),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isExporting) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF40916C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF40916C)),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Generating export file...',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startExport,
              icon: const Icon(CupertinoIcons.cloud_download,
                  color: Colors.white),
              label: Text(
                'Export Expenses',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Test button for debugging Excel export
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testExcelExport,
              icon: const Icon(CupertinoIcons.wrench, color: Color(0xFF1B4332)),
              label: Text(
                'Test Excel Export (Debug)',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1B4332),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1B4332)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your file will be downloaded to your device\'s Downloads folder.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
