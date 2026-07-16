import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// dart:io is only available on mobile/desktop, not on the web.
// Firebase Storage image upload is conditionally compiled using kIsWeb.
// ignore: uri_does_not_exist
import 'package:smart_census/services/sync_service_io.dart'
    if (dart.library.html) 'package:smart_census/services/sync_service_web.dart'
    as platform_upload;

class SyncService {
  final _firestore = FirebaseFirestore.instance;
  final DatabaseService _localDb = DatabaseService();

  /// Upload all pending surveys to Firestore.
  Future<int> uploadPendingSurveys() async {
    final allSurveys = _localDb.getAllSurveys();
    final pendingSurveys = allSurveys.where((s) => !s.isSynced).toList();
    int syncedCount = 0;

    for (var survey in pendingSurveys) {
      try {
        await _uploadSingleSurvey(survey);
        syncedCount++;
      } catch (e) {
        print('Failed to sync survey ${survey.id}: $e');
      }
    }
    return syncedCount;
  }

  /// Upload a single survey with its images (platform-adaptive).
  Future<void> _uploadSingleSurvey(SurveyModel survey) async {
    // 1. Upload images conditionally (mobile/desktop only; skipped on web)
    List<String> cloudImageUrls = [];
    if (!kIsWeb) {
      for (final localPath in survey.documentPaths) {
        final url = await platform_upload.uploadImage(localPath, survey.id);
        if (url != null) cloudImageUrls.add(url);
      }
    }

    // 2. Get surveyor info from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final surveyorPhone = prefs.getString('user_phone') ?? 'unknown';
    final surveyorName = prefs.getString('surveyor_name') ?? 'Surveyor';

    // 3. Prepare data map for Firestore
    final data = survey.toJson();
    data['documentUrls'] = cloudImageUrls;
    data['surveyorPhone'] = surveyorPhone;
    data['surveyorName'] = surveyorName;

    // 4. Write to Firestore
    await _firestore.collection('surveys').doc(survey.id).set(data);

    // 5. Update local record with synced status
    final updatedSurvey = SurveyModel(
      id: survey.id,
      householdId: survey.householdId,
      address: survey.address,
      latitude: survey.latitude,
      longitude: survey.longitude,
      members: survey.members,
      documentPaths: survey.documentPaths,
      documentUrls: cloudImageUrls,
      isSynced: true,
      status: 'Uploaded',
      timestamp: survey.timestamp,
      aiVerified: survey.aiVerified,
      blockchainHash: survey.blockchainHash,
    );

    await DatabaseService().saveSurvey(updatedSurvey);
  }
}
