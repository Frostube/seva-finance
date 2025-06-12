import 'dart:io'; // For File type
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'review_receipt_screen.dart'; // We'll navigate here

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
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

  void _processImageAndReview() {
    if (_selectedImage == null) return;
    // For now, navigate with mock data. OCR processing will be added later.
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: Colors.black87, size: 22),
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
              if (_selectedImage == null)
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
                        'Add a receipt by taking a photo or uploading an image.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600]),
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
                          fit: BoxFit.contain, // Use contain to see the whole image
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        child: CupertinoButton(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(30),
                          padding: const EdgeInsets.all(12),
                          onPressed: _processImageAndReview,
                          child: const Icon(CupertinoIcons.check_mark, color: Colors.white, size: 28),
                        ),
                      )
                    ],
                  ),
                ),
              const SizedBox(height: 30),
              if (_selectedImage == null) ...[
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
              ] else ...[
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
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red[600] : Theme.of(context).primaryColor;
    final textColor = isDestructive ? Colors.red[600] : Theme.of(context).primaryColor;
    final backgroundColor = isDestructive ? Colors.red[50] : const Color(0xFFE9F1EC); // App's pale green

    return ElevatedButton.icon(
      icon: Icon(icon, color: color, size: 20),
      label: Text(
        label,
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
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