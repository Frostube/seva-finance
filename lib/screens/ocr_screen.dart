import 'dart:io'; // For File type
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb and Uint8List
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'review_receipt_screen.dart'; // We'll navigate here

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  File? _selectedImage;
  File? _selectedPdf;
  String? _extractedPdfText;
  bool _isProcessingPdf = false;
  String? _pdfFileName; // For web platform
  Uint8List? _pdfBytes; // For web platform
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _selectedPdf = null; // Clear PDF if image is selected
          _extractedPdfText = null;
        });
      }
    } catch (e) {
      // Handle exceptions, e.g., permission denied
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null) {
        PlatformFile file = result.files.single;

        setState(() {
          _isProcessingPdf = true;
          _selectedImage = null; // Clear image if PDF is selected
        });

        // Handle web platform (uses bytes) vs mobile/desktop (uses path)
        if (kIsWeb) {
          if (file.bytes != null) {
            setState(() {
              _pdfFileName = file.name;
              _pdfBytes = file.bytes!;
            });
            await _extractTextFromPdfBytes(file.bytes!, file.name);
          }
        } else {
          // For mobile/desktop platforms
          if (file.path != null) {
            final pdfFile = File(file.path!);
            setState(() {
              _selectedPdf = pdfFile;
            });
            await _extractTextFromPdf(pdfFile);
          }
        }
      }
    } catch (e) {
      print('Error picking PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking PDF: ${e.toString()}')),
      );
      setState(() {
        _isProcessingPdf = false;
      });
    }
  }

  Future<void> _extractTextFromPdf(File pdfFile) async {
    try {
      // Load the PDF document
      final PdfDocument document =
          PdfDocument(inputBytes: pdfFile.readAsBytesSync());

      // Extract text from all pages
      String extractedText = '';
      for (int i = 0; i < document.pages.count; i++) {
        extractedText += PdfTextExtractor(document)
            .extractText(startPageIndex: i, endPageIndex: i);
        extractedText += '\n'; // Add newline between pages
      }

      // Close the document
      document.dispose();

      setState(() {
        _selectedPdf = pdfFile;
        _extractedPdfText = extractedText.trim();
        _isProcessingPdf = false;
      });

      print('Extracted PDF text: $_extractedPdfText');
    } catch (e) {
      print('Error extracting text from PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isProcessingPdf = false;
        _selectedPdf = null;
        _extractedPdfText = null;
      });
    }
  }

  Future<void> _extractTextFromPdfBytes(
      Uint8List pdfBytes, String fileName) async {
    try {
      // Load the PDF document from bytes
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

      // Extract text from all pages
      String extractedText = '';
      for (int i = 0; i < document.pages.count; i++) {
        extractedText += PdfTextExtractor(document)
            .extractText(startPageIndex: i, endPageIndex: i);
        extractedText += '\n'; // Add newline between pages
      }

      // Close the document
      document.dispose();

      setState(() {
        _extractedPdfText = extractedText.trim();
        _isProcessingPdf = false;
      });

      print('Extracted PDF text from web: $_extractedPdfText');
    } catch (e) {
      print('Error extracting text from PDF bytes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isProcessingPdf = false;
        _pdfFileName = null;
        _pdfBytes = null;
        _extractedPdfText = null;
      });
    }
  }

  void _processImageAndReview() {
    if (_selectedImage != null) {
      // Process image as before
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewReceiptScreen(
            imagePath: _selectedImage!.path,
            transactionDate: DateTime.now(), // Mock
            transactionTime: TimeOfDay.now(), // Mock
            ocrResults: const [], // Pass an empty list for now
          ),
        ),
      );
    } else if (_extractedPdfText != null) {
      // Process PDF text and navigate
      final ocrResults = _parsePdfTextToOcrResults(_extractedPdfText!);

      // Handle path for both web and mobile/desktop
      String pdfPath = '';
      if (kIsWeb && _pdfFileName != null) {
        pdfPath = _pdfFileName!; // Use filename for web
      } else if (_selectedPdf != null) {
        pdfPath = _selectedPdf!.path; // Use path for mobile/desktop
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewReceiptScreen(
            imagePath: pdfPath,
            transactionDate: DateTime.now(),
            transactionTime: TimeOfDay.now(),
            ocrResults: ocrResults,
          ),
        ),
      );
    }
  }

  List<Map<String, String>> _parsePdfTextToOcrResults(String text) {
    List<Map<String, String>> results = [];
    List<String> lines =
        text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    // Enhanced extraction variables
    String? businessName;
    String? invoiceNumber;
    String? issueDate;
    String? dueDate;
    String? subtotal;
    String? taxAmount;
    String? taxRate;
    String? finalTotal;
    List<Map<String, String>> itemizedList = [];

    print('PDF Parsing: Processing ${lines.length} lines');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      String lowerLine = line.toLowerCase();

      // 🏢 Business Name Detection (simplified)
      if (businessName == null) {
        // PRIORITY 1: Lines with business suffixes (most reliable)
        if (RegExp(r'\b(s\.l\.|partners|ltd|llc|inc|corp|gmbh|ag|sa|bv)\b',
                    caseSensitive: false)
                .hasMatch(line) &&
            line.length > 5 &&
            line.length < 60 &&
            !line.contains(',') &&
            !lowerLine.contains('referencia') &&
            !lowerLine.contains('internacional') &&
            !lowerLine.contains('iban')) {
          businessName = line.trim();
          print('Found business name with suffix: $businessName');
        }
      }

      // 📄 Invoice Number
      if (invoiceNumber == null) {
        RegExp invRegex = RegExp(r'(?:invoice|inv)[\s#-]*([a-z0-9\-]+)',
            caseSensitive: false);
        var match = invRegex.firstMatch(line);
        if (match != null) {
          invoiceNumber = match.group(1);
        }
      }

      // 📅 Issue Date (enhanced patterns)
      if (issueDate == null) {
        if (lowerLine.contains('issued on') ||
            lowerLine.contains('date of sale')) {
          RegExp dateRegex = RegExp(
              r'(\d{1,2}\s+\w+\s+\d{4}|\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})');
          var match = dateRegex.firstMatch(line);
          if (match != null) {
            issueDate = match.group(1);
          }
        }
      }

      // ⏰ Due Date
      if (dueDate == null && lowerLine.contains('due date')) {
        RegExp dateRegex = RegExp(
            r'(\d{1,2}\s+\w+\s+\d{4}|\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})');
        var match = dateRegex.firstMatch(line);
        if (match != null) {
          dueDate = match.group(1);
        }
      }

      // 🛒 ITEMIZED SECTION - Multi-line Detection
      if (_isItemDescriptionLine(line, lines, i)) {
        var itemData = _parseMultiLineItem(lines, i);
        if (itemData.isNotEmpty) {
          itemizedList.add(itemData);
          print(
              'Found item: ${itemData['description']} - ${itemData['amount']}');
        }
      }

      // 💰 Financial Totals (Enhanced)
      if (lowerLine.contains('subtotal') && subtotal == null) {
        RegExp amountRegex =
            RegExp(r'[€\$£]?(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)');
        var match = amountRegex.firstMatch(line);
        if (match != null) {
          subtotal = match.group(1)?.replaceAll(',', '');
        }
      }

      if (lowerLine.contains('vat') || lowerLine.contains('tax')) {
        // Extract tax rate
        if (taxRate == null) {
          RegExp taxRateRegex = RegExp(r'(\d+)%');
          var match = taxRateRegex.firstMatch(line);
          if (match != null) {
            taxRate = '${match.group(1)}%';
          }
        }
        // Extract tax amount
        if (taxAmount == null) {
          RegExp amountRegex =
              RegExp(r'[€\$£]?(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)');
          var match = amountRegex.firstMatch(line);
          if (match != null) {
            taxAmount = match.group(1)?.replaceAll(',', '');
          }
        }
      }

      if ((lowerLine.contains('total') && !lowerLine.contains('subtotal')) &&
          finalTotal == null) {
        // Check current line for amount
        RegExp amountRegex =
            RegExp(r'[€\$£]?(\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})?)');
        var match = amountRegex.firstMatch(line);
        if (match != null) {
          finalTotal = match.group(1)?.replaceAll(',', '');
        }
        // If no amount on current line, check previous line
        else if (i > 0) {
          String prevLine = lines[i - 1].trim();
          var prevMatch = amountRegex.firstMatch(prevLine);
          if (prevMatch != null) {
            finalTotal = prevMatch.group(1)?.replaceAll(',', '');
          }
        }
      }
    }

    // 🏗️ BUILD STRUCTURED RESULTS
    print(
        'PDF Parsing Results: Business: $businessName, Items: ${itemizedList.length}, Total: $finalTotal');

    if (businessName != null) {
      results.add({'label': 'Store Name', 'value': businessName});
    }
    if (invoiceNumber != null) {
      results.add({'label': 'Invoice Number', 'value': invoiceNumber});
    }
    if (issueDate != null) {
      results.add({'label': 'Date', 'value': issueDate});
    }
    if (dueDate != null) {
      results.add({'label': 'Due Date', 'value': dueDate});
    }

    // Add itemized breakdown - Separate description and price
    for (int i = 0; i < itemizedList.length; i++) {
      var item = itemizedList[i];
      results
          .add({'label': 'Item ${i + 1}', 'value': item['description'] ?? ''});
      results.add({
        'label': 'Price ${i + 1}',
        'value': item['amount'] ?? item['rate'] ?? ''
      });
    }

    if (subtotal != null) {
      results.add({'label': 'Subtotal', 'value': subtotal});
    }
    if (taxRate != null && taxAmount != null) {
      results.add({'label': 'Tax ($taxRate)', 'value': taxAmount});
    }
    if (finalTotal != null) {
      results.add({'label': 'Total Amount', 'value': finalTotal});
    }

    return results;
  }

  // 🔍 Helper: Check if this line starts an item description
  bool _isItemDescriptionLine(String line, List<String> allLines, int index) {
    // Look for service/product descriptions that are followed by price patterns
    if (line.length < 3 || line.length > 100) return false;

    String trimmedLine = line.trim();
    String lowerLine = trimmedLine.toLowerCase();

    // Skip obvious non-item lines
    if (lowerLine.contains('total') ||
        lowerLine.contains('subtotal') ||
        lowerLine.contains('vat') ||
        lowerLine.contains('tax') ||
        lowerLine.contains('invoice') ||
        lowerLine.contains('from') ||
        lowerLine.contains('billed') ||
        lowerLine.contains('pay this') ||
        lowerLine.contains('scan the') ||
        lowerLine.contains('click here') ||
        lowerLine.contains('page') ||
        lowerLine.contains('item') ||
        lowerLine.contains('name') ||
        lowerLine.contains('description') ||
        lowerLine.contains('price') ||
        lowerLine.contains('quantity') ||
        lowerLine.contains('amount') ||
        lowerLine.contains('note') ||
        lowerLine.contains('iban') ||
        lowerLine.contains('swift') ||
        lowerLine.startsWith('€') ||
        lowerLine.startsWith('\$') ||
        lowerLine.startsWith('£') ||
        RegExp(r'^\d+%?$').hasMatch(trimmedLine) ||
        RegExp(r'^[€\$£]?\d+(?:[,\.]\d{3})*(?:[,\.]\d{2})?$')
            .hasMatch(trimmedLine)) {
      return false;
    }

    // Look for the itemized section - must be after headers like "Amount"
    bool foundItemHeaders = false;
    for (int i = 0; i < index; i++) {
      String prevLine = allLines[i].trim().toLowerCase();
      if (prevLine == 'amount' ||
          prevLine == 'tax rate' ||
          prevLine == 'quantity') {
        foundItemHeaders = true;
        break;
      }
    }

    if (!foundItemHeaders) return false;

    // Check if next few lines contain the exact price sequence pattern
    List<String> nextLines = [];
    for (int i = index + 1; i < index + 5 && i < allLines.length; i++) {
      nextLines.add(allLines[i].trim());
    }

    // Look for the pattern: Price, Quantity, Tax%, Amount
    if (nextLines.length >= 4) {
      bool hasValidPrice =
          RegExp(r'^[€\$£]?\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})$')
              .hasMatch(nextLines[0]);
      bool hasValidQuantity = RegExp(r'^\d+$').hasMatch(nextLines[1]);
      bool hasValidTaxRate = RegExp(r'^\d+%$').hasMatch(nextLines[2]);
      bool hasValidAmount =
          RegExp(r'^[€\$£]?\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})$')
              .hasMatch(nextLines[3]);

      return hasValidPrice &&
          hasValidQuantity &&
          hasValidTaxRate &&
          hasValidAmount;
    }

    return false;
  }

  // 🧩 Helper: Parse multi-line item starting from description line
  Map<String, String> _parseMultiLineItem(
      List<String> allLines, int startIndex) {
    Map<String, String> itemData = {};

    // Get the description (current line)
    String description = allLines[startIndex].trim();
    itemData['description'] = description;

    // Look ahead for price, quantity, tax rate, and amount in next lines
    String? price;
    String? quantity;
    String? taxRate;
    String? amount;

    for (int i = startIndex + 1;
        i < startIndex + 6 && i < allLines.length;
        i++) {
      String line = allLines[i].trim();

      // Price pattern (€2,000.00)
      if (price == null &&
          RegExp(r'^[€\$£]?\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})$')
              .hasMatch(line)) {
        price = line.replaceAll(RegExp(r'^[€\$£]'), '');
      }
      // Quantity pattern (just a number like "1")
      else if (quantity == null && RegExp(r'^\d+$').hasMatch(line)) {
        quantity = line;
      }
      // Tax rate pattern (21%)
      else if (taxRate == null && RegExp(r'^\d+%$').hasMatch(line)) {
        taxRate = line;
      }
      // Amount pattern (€2,420.00) - usually the largest amount or last one
      else if (RegExp(r'^[€\$£]?\d{1,3}(?:[,\.]\d{3})*(?:[,\.]\d{2})$')
          .hasMatch(line)) {
        String cleanAmount = line.replaceAll(RegExp(r'^[€\$£]'), '');
        // If we already have a price, this might be the total amount
        if (price != null && cleanAmount != price) {
          amount = cleanAmount;
        } else if (price == null) {
          price = cleanAmount;
        }
      }
    }

    // Set values or defaults (clean number format)
    itemData['rate'] = (price ?? '0').replaceAll(',', '');
    itemData['quantity'] = quantity ?? '1';
    itemData['tax_rate'] = taxRate ?? '';
    itemData['amount'] = (amount ?? price ?? '0').replaceAll(',', '');

    print(
        'Multi-line parse: ${itemData['description']} | Price: ${itemData['rate']} | Qty: ${itemData['quantity']} | Tax: ${itemData['tax_rate']} | Amount: ${itemData['amount']}');

    return itemData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevent default back button
        leading: IconButton(
          icon:
              const Icon(CupertinoIcons.xmark, color: Colors.black87, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Scan Receipt',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_selectedImage == null &&
                  _selectedPdf == null &&
                  _pdfBytes == null &&
                  !_isProcessingPdf)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.doc_text_viewfinder,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Add a receipt by taking a photo, uploading an image, or selecting a PDF.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              else if (_isProcessingPdf)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CupertinoActivityIndicator(radius: 20),
                      const SizedBox(height: 20),
                      Text(
                        'Processing PDF...',
                        style: GoogleFonts.inter(
                            fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Extracting text from your receipt',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              else if (_selectedPdf != null ||
                  (_pdfBytes != null && _pdfFileName != null))
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F1EC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              CupertinoIcons.doc_text_fill,
                              size: 60,
                              color: const Color(0xFF1B4332),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'PDF Ready',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1B4332),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Text extracted successfully',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_extractedPdfText != null &&
                          _extractedPdfText!.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _extractedPdfText!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _processImageAndReview,
                        icon: const Icon(CupertinoIcons.arrow_right_circle_fill,
                            color: Colors.white),
                        label: Text(
                          'Review & Save',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4332),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit
                              .contain, // Use contain to see the whole image
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        child: CupertinoButton(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(30),
                          padding: const EdgeInsets.all(12),
                          onPressed: _processImageAndReview,
                          child: const Icon(CupertinoIcons.check_mark,
                              color: Colors.white, size: 28),
                        ),
                      )
                    ],
                  ),
                ),
              const SizedBox(height: 30),
              if (_selectedImage == null &&
                  _selectedPdf == null &&
                  _pdfBytes == null &&
                  !_isProcessingPdf) ...[
                _buildOptionButton(
                  context,
                  icon: CupertinoIcons.camera_fill,
                  label: 'Take Photo',
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: 16),
                _buildOptionButton(
                  context,
                  icon: CupertinoIcons.photo_on_rectangle,
                  label: 'Upload Image',
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(height: 16),
                _buildOptionButton(
                  context,
                  icon: CupertinoIcons.doc_text,
                  label: 'Upload PDF Receipt',
                  onPressed: _pickPdfFile,
                ),
              ] else if (_selectedImage != null) ...[
                // Option to clear or re-select image
                _buildOptionButton(
                  context,
                  icon: CupertinoIcons.clear_circled_solid,
                  label: 'Clear Image',
                  isDestructive: true,
                  onPressed: () {
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
              ] else if (_selectedPdf != null ||
                  (_pdfBytes != null && _pdfFileName != null)) ...[
                // Option to clear PDF
                _buildOptionButton(
                  context,
                  icon: CupertinoIcons.clear_circled_solid,
                  label: 'Clear PDF',
                  isDestructive: true,
                  onPressed: () {
                    setState(() {
                      _selectedPdf = null;
                      _pdfBytes = null;
                      _pdfFileName = null;
                      _extractedPdfText = null;
                    });
                  },
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    final color =
        isDestructive ? Colors.red[600] : Theme.of(context).primaryColor;
    final textColor =
        isDestructive ? Colors.red[600] : Theme.of(context).primaryColor;
    final backgroundColor = isDestructive
        ? Colors.red[50]
        : const Color(0xFFE9F1EC); // App's pale green

    return ElevatedButton.icon(
      icon: Icon(icon, color: color, size: 20),
      label: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: color, // For ripple effect if needed
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // side: BorderSide(color: color!), // Optional border
        ),
        elevation: 0,
      ),
    );
  }
}
