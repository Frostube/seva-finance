import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // For date/time formatting if needed
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
// Added for type safety
import '../services/expense_service.dart';
import '../services/category_service.dart';
import 'ocr_settings_screen.dart'; // Added for navigation
// For potential future use of settings in this screen
// For potential future use

class ReviewReceiptScreen extends StatefulWidget {
  // Mock data for now - in the future, this will come from OCR
  final String imagePath; // Path to the displayed receipt image
  final String merchantName;
  final DateTime transactionDate;
  final TimeOfDay transactionTime;
  final List<Map<String, String>> lineItems; // e.g., [{'item': 'Coffee', 'price': '2.50'}]
  final String totalAmount;
  final String? changeAmount;
  final List<Map<String, String>> ocrResults; 

  const ReviewReceiptScreen({
    super.key,
    required this.imagePath, // We'll add a placeholder for now
    this.merchantName = 'Breakfast joint', // Mock
    required this.transactionDate, // Mock
    required this.transactionTime, // Mock
    this.lineItems = const [
      {'item': 'Music City Platter', 'price': '19'},
      {'item': 'French Toast with Bacon', 'price': '12'},
      {'item': 'French Toast (2)', 'price': '5'},
    ], // Mock
    this.totalAmount = '36', // Mock
    this.changeAmount = '14', // Mock
    required this.ocrResults, 
  });

  @override
  State<ReviewReceiptScreen> createState() => _ReviewReceiptScreenState();
}

class _ReviewReceiptScreenState extends State<ReviewReceiptScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameController;
  late TextEditingController _dateController;
  late TextEditingController _totalAmountController;
  final List<TextEditingController> _itemControllers = [];
  final List<TextEditingController> _priceControllers = [];
  late String _selectedCategoryName = 'Other'; // Stores the NAME of the selected category
  late CategoryService _categoryService;
  List<String> _categoryDisplayNames = []; // For Dropdown
  bool _isLoadingCategories = true;

  // TODO: Implement "Settings" functionality for OCR options
  // TODO: Implement "Download/Save" functionality for the receipt image

  @override
  void initState() {
    super.initState();
    _categoryService = Provider.of<CategoryService>(context, listen: false);
    
    _storeNameController = TextEditingController(text: _extractOcrField('Store Name'));
    _dateController = TextEditingController(text: _extractOcrField('Date'));
    _totalAmountController = TextEditingController(text: _extractOcrField('Total Amount'));

    _populateItemAndPriceControllers();
    _loadCategoriesAndInitSelection();
  }

  String? _extractOcrField(String label, {bool throwIfNotFound = false}) {
    try {
      return widget.ocrResults.firstWhere((e) => e['label'] == label)['value'];
    } catch (e) {
      if (throwIfNotFound) {
        debugPrint("ReviewReceiptScreen: OCR field '$label' not found in ocrResults.");
      }
      return null; // Return null if not found
    }
  }

  void _populateItemAndPriceControllers() {
    for (int i = 0; ; i++) {
      final itemLabel = 'Item ${i + 1}';
      final priceLabel = 'Price ${i + 1}';
      final itemValue = _extractOcrField(itemLabel, throwIfNotFound: false);
      final priceValue = _extractOcrField(priceLabel, throwIfNotFound: false);

      if (itemValue != null) {
        _itemControllers.add(TextEditingController(text: itemValue));
        _priceControllers.add(TextEditingController(text: priceValue ?? ''));
      } else {
        break; 
      }
    }
  }

  Future<void> _loadCategoriesAndInitSelection() async {
    setState(() { _isLoadingCategories = true; });
    // Ensure CategoryService is initialized
    if (_categoryService.initializationComplete != null) {
      await _categoryService.initializationComplete;
    }
    if (!mounted) return;

    final activeCategories = _categoryService.categories.where((cat) => cat.id != CategoryService.uncategorizedId || cat.name == CategoryService.uncategorizedName).toList();
    
    setState(() {
      _categoryDisplayNames = activeCategories.map((c) => c.name).toList();
      if (_categoryDisplayNames.isNotEmpty) {
        // Try to select 'Other' if available, else the first category
        if (_categoryDisplayNames.contains('Other')) {
          _selectedCategoryName = 'Other';
        } else if (_categoryDisplayNames.contains(CategoryService.uncategorizedName)){
           _selectedCategoryName = CategoryService.uncategorizedName;
        } else {
          _selectedCategoryName = _categoryDisplayNames.first;
        }
      } else {
        // Fallback if no categories exist (should ideally not happen if Uncategorized is always there)
        _selectedCategoryName = CategoryService.uncategorizedName; 
        _categoryDisplayNames.add(CategoryService.uncategorizedName);
      }
      _isLoadingCategories = false;
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _dateController.dispose();
    _totalAmountController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    for (var controller in _priceControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final totalAmount = double.tryParse(_totalAmountController.text.replaceAll('\$', '')) ?? 0.0;
      
      DateTime parsedDate;
      try {
        parsedDate = DateFormat('yyyy-MM-dd').parseStrict(_dateController.text);
      } catch (e) {
        try {
          parsedDate = DateFormat('MM/dd/yyyy').parseStrict(_dateController.text);
        } catch (f) {
          try {
            parsedDate = DateFormat('dd.MM.yyyy').parseStrict(_dateController.text);
          } catch (g) {
            try {
               parsedDate = DateFormat('dd-MM-yyyy').parseStrict(_dateController.text);
            } catch (h) {
                debugPrint("ReviewReceiptScreen: Could not parse date: ${_dateController.text}. Defaulting to now.");
                parsedDate = DateTime.now();
            }
          }
        }
      }

      String categoryIdToSave = CategoryService.uncategorizedId; // Default to uncategorized
      try {
        final foundCategory = _categoryService.categories.firstWhere((cat) => cat.name == _selectedCategoryName);
        categoryIdToSave = foundCategory.id;
      } catch (e) {
        debugPrint("ReviewReceiptScreen: Selected category name '$_selectedCategoryName' not found, saving as Uncategorized. Error: $e");
        // Ensure Uncategorized category exists and get its ID, just in case
        final uncategorized = await _categoryService.getOrCreateUncategorizedCategory();
        categoryIdToSave = uncategorized.id;
      }

      final newExpense = Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: totalAmount,
        categoryId: categoryIdToSave, 
        date: parsedDate,
        note: "Scanned: ${_storeNameController.text}",
      );

      final expenseService = Provider.of<ExpenseService>(context, listen: false);
      await expenseService.addExpense(newExpense);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense saved from receipt!', style: GoogleFonts.inter())),
        );
        Navigator.of(context).pop(); 
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _downloadImage() async {
    final photosStatus = await Permission.photos.request(); // For iOS
    final storageStatus = await Permission.storage.request(); // For Android

    if (photosStatus.isGranted || storageStatus.isGranted) {
      try {
        final result = await ImageGallerySaver.saveFile(widget.imagePath, name: "receipt_${DateTime.now().millisecondsSinceEpoch}");
        if (!mounted) return;
        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image saved to gallery!', style: GoogleFonts.inter())),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save image: ${result['errorMessage'] ?? 'Unknown error'}', style: GoogleFonts.inter())),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e', style: GoogleFonts.inter())),
        );
      }
    } else if (photosStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo/Storage permission permanently denied. Please enable it in app settings.', style: GoogleFonts.inter()),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo/Storage permission denied.', style: GoogleFonts.inter())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Review Receipt',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.settings, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OcrSettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.download_circle, color: Colors.black87),
            onPressed: _downloadImage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Verify Extracted Information',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Center(
                child: Image.file(
                  File(widget.imagePath),
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint("ReviewReceiptScreen: Error loading image for preview: $error");
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.photo_fill_on_rectangle_fill, size: 50, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text("Error loading image", style: GoogleFonts.inter(color: Colors.grey[700])),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(_storeNameController, 'Store Name', CupertinoIcons.building_2_fill),
              _buildTextField(_dateController, 'Date (YYYY-MM-DD)', CupertinoIcons.calendar, keyboardType: TextInputType.datetime),
              _buildTextField(_totalAmountController, 'Total Amount', CupertinoIcons.money_dollar_circle_fill, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 16),
              Text(
                'Assign Category',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!)
                ),
                child: _isLoadingCategories
                  ? const Center(child: CupertinoActivityIndicator(radius: 10))
                  : DropdownButtonFormField<String>(
                      value: _categoryDisplayNames.contains(_selectedCategoryName) ? _selectedCategoryName : (_categoryDisplayNames.isNotEmpty ? _categoryDisplayNames.first : null),
                      items: _categoryDisplayNames.map((String categoryName) {
                        return DropdownMenuItem<String>(
                          value: categoryName,
                          child: Text(categoryName, style: GoogleFonts.inter()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategoryName = newValue;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please select a category' : null,
                      hint: _categoryDisplayNames.isEmpty ? Text("No categories", style: GoogleFonts.inter()) : null,
                    ),
              ),
              const SizedBox(height: 20),
              if (_itemControllers.isNotEmpty)
                Text(
                  'Items (Read-only)',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                ),
              if (_itemControllers.isNotEmpty) const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _itemControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _buildTextField(_itemControllers[index], 'Item ${index + 1}', CupertinoIcons.tag_fill, readOnly: true, dense: true),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(_priceControllers[index], 'Price', CupertinoIcons.money_dollar, readOnly: true, dense: true, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, MediaQuery.of(context).padding.bottom + 16.0),
        child: ElevatedButton.icon(
          icon: const Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.white),
          label: Text('Save Expense', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          onPressed: _saveExpense,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B4332),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, bool readOnly = false, bool dense = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 4.0 : 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        style: GoogleFonts.inter(color: readOnly ? Colors.grey[700] : Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: const Color(0xFF1B4332), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[300]!)
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey[300]!)
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF1B4332))
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: dense ? 12.0 : 16.0, horizontal: 12.0),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          final cleanValue = value?.trim() ?? '';
          if (!readOnly && cleanValue.isEmpty) {
            if (label == 'Store Name' || label.startsWith('Date') || label == 'Total Amount') {
               return 'Please enter $label';
            }
          }
          if (label == 'Total Amount') {
             final numVal = double.tryParse(cleanValue.replaceAll('\$', ''));
             if (numVal == null || numVal <= 0) return 'Please enter a valid amount';
          }
          return null;
        },
      ),
    );
  }
}

// Example usage (for testing in a separate view or main.dart temporarily):
// Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewReceiptScreen(
//   imagePath: '', // a placeholder path
//   transactionDate: DateTime(2019, 7, 1),
//   transactionTime: TimeOfDay(hour: 10, minute: 12),
// ))); 