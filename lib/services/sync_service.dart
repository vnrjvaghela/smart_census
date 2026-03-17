import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/services/database_service.dart';

class SyncService {
  final _firestore = FirebaseFirestore.instance; // Lazy init locally if needed
  final _storage = FirebaseStorage.instance;
  final DatabaseService _localDb = DatabaseService();

  // Upload all pending surveys
  Future<int> uploadPendingSurveys() async {
    final allSurveys = _localDb.getAllSurveys();
    final pendingSurveys = allSurveys.where((s) => !s.isSynced).toList();
    int syncedCount = 0;

    for (var survey in pendingSurveys) {
      try {
        await _uploadSingleSurvey(survey);
        syncedCount++;
      } catch (e) {
        print("Failed to sync survey ${survey.id}: $e");
      }
    }
    return syncedCount;
  }

  // Upload a single survey including its images
  Future<void> _uploadSingleSurvey(SurveyModel survey) async {
    // 1. Upload Images and get URLs
    List<String> cloudImageUrls = [];
    
    for (String localPath in survey.documentPaths) {
      final url = await _uploadImage(localPath, survey.id);
      if (url != null) cloudImageUrls.add(url);
    }
    
    // 2. Prepare Data for Firestore
    final data = survey.toJson();
    data['documentUrls'] = cloudImageUrls; // Sync cloud URLs to Firestore
    
    // 3. Upload to Firestore
    await _firestore.collection('surveys').doc(survey.id).set(data);

    // 4. Update Local Status
    final updatedSurvey = SurveyModel(
      id: survey.id,
      householdId: survey.householdId,
      address: survey.address,
      latitude: survey.latitude,
      longitude: survey.longitude,
      members: survey.members,
      documentPaths: survey.documentPaths,
      documentUrls: cloudImageUrls, // Save cloud URLs locally too
      isSynced: true, // Mark as Synced
      status: 'Uploaded',
      timestamp: survey.timestamp,
      aiVerified: survey.aiVerified,
      blockchainHash: survey.blockchainHash,
    );

    await DatabaseService().saveSurvey(updatedSurvey);
  }

  // Helper: Upload Image to Firebase Storage
  Future<String?> _uploadImage(String filePath, String surveyId) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final fileName = filePath.split('/').last;
      final destination = 'surveys/$surveyId/$fileName';

      final ref = _storage.ref(destination);
      await ref.putFile(file);
      
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }
}
