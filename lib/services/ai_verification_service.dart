import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class AiVerificationService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  // Analyze an image and return true if it seems like a valid document
  Future<bool> verifyDocument(String localImagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(localImagePath);
      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final String fullText = recognizedText.text.toLowerCase();

      // Let's look for common government keywords or patterns
      // In a real production model, this would be a custom trained TFLite Model
      // or complex Regex. For now we look for keywords like "caste", "aadhaar", "government".

      bool hasKeywords = fullText.contains("caste") ||
          fullText.contains("government") ||
          fullText.contains("aadhaar") ||
          fullText.contains("certificate");

      // Aadhaar 12-digit pattern (e.g. 1234 5678 9012 or 123456789012)
      final RegExp aadhaarRegEx = RegExp(r'\d{4}\s?\d{4}\s?\d{4}');
      bool hasAadhaarMatch = aadhaarRegEx.hasMatch(fullText);

      return (hasKeywords || hasAadhaarMatch);
    } catch (e) {
      print("OCR Error: $e");
      return false; // If we can't read it, it's not verified
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
