import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OCRService {
  static final String _veryfiApiKey = dotenv.env['VERYFI_API_KEY'] ?? '';
  static final String _veryfiClientId = dotenv.env['VERYFI_CLIENT_ID'] ?? '';
  static final String _veryfiUsername = dotenv.env['VERYFI_USERNAME'] ?? '';
  static final String _veryfiBaseUrl = 'https://api.veryfi.com/api/v8/partner';
  
  static final String _mindeeApiKey = dotenv.env['MINDEE_API_KEY'] ?? '';
  static final String _mindeeBaseUrl = 'https://api.mindee.net/v1/products/mindee/expense_receipts/v5/predict';
  
  /// Processes a receipt image using Veryfi OCR API
  /// Returns the raw JSON response from the API
  Future<Map<String, dynamic>> processReceiptWithVeryfi(String imagePath) async {
    if (_veryfiApiKey.isEmpty || _veryfiClientId.isEmpty || _veryfiUsername.isEmpty) {
      throw Exception('Veryfi API credentials not configured');
    }
    
    final bytes = await _getImageBytes(imagePath);
    final base64Image = base64Encode(bytes);
    
    final url = '$_veryfiBaseUrl/documents';
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Client-Id': _veryfiClientId,
      'Authorization': 'apikey $_veryfiApiKey',
    };
    
    final body = jsonEncode({
      'file_name': 'receipt.jpg',
      'file_data': base64Image,
      'categories': ['Grocery', 'Utilities', 'Dining', 'Entertainment', 'Transportation'],
      'auto_delete': false,
    });
    
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to process receipt: ${response.body}');
    }
  }
  
  /// Processes a receipt image using Mindee OCR API
  /// Returns the raw JSON response from the API
  Future<Map<String, dynamic>> processReceiptWithMindee(String imagePath) async {
    if (_mindeeApiKey.isEmpty) {
      throw Exception('Mindee API key not configured');
    }
    
    final bytes = await _getImageBytes(imagePath);
    
    final request = http.MultipartRequest('POST', Uri.parse(_mindeeBaseUrl));
    request.headers.addAll({
      'Authorization': 'Token $_mindeeApiKey',
    });
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'document',
        bytes,
        filename: 'receipt.jpg',
      ),
    );
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to process receipt: ${response.body}');
    }
  }
  
  /// Helper method to get image bytes from path
  Future<List<int>> _getImageBytes(String imagePath) async {
    final file = await http.get(Uri.parse(imagePath));
    return file.bodyBytes;
  }
} 