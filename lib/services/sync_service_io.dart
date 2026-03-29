import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Mobile/Desktop implementation: uploads a file from local disk to Firebase Storage.
Future<String?> uploadImage(String filePath, String surveyId) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final fileName = filePath.split('/').last;
    final destination = 'surveys/$surveyId/$fileName';

    final ref = FirebaseStorage.instance.ref(destination);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  } catch (e) {
    print('Error uploading image: $e');
    return null;
  }
}
