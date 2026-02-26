// import 'dart:io';
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
    
    // For MVP and cross-platform compatibility without heavy blob storage,
    // we bypass actual file upload on web unless implemented with bytes.
    // Assuming mobile for `File` usage if `kIsWeb` is false.
    // If you need cross-platform uploads, you'd fetch bytes from the blob URL on web or pass XFile.
    
    // 2. Prepare Data for Firestore
    final data = survey.toJson();
    data['documentUrls'] = cloudImageUrls; // Add cloud URLs (empty for now on web)
    
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
      isSynced: true, // Mark as Synced
      status: 'Uploaded',
      timestamp: survey.timestamp,
    );

    await _localDb.saveSurvey(updatedSurvey);
  }

  // Helper: Upload Image to Firebase Storage (Requires dart:io context)
  // Future<String?> _uploadImage(String filePath, String surveyId) async { ... }
}
