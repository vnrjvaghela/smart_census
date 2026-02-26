import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_census/models/survey_model.dart';
import 'package:smart_census/models/family_member_model.dart';

class DatabaseService {
  static const String surveyBoxName = 'surveys';

  // Initialize Hive and Open Boxes (Call this in main.dart)
  static Future<void> init() async {
    print("DEBUG: DatabaseService.init started");
    try {
      await Hive.initFlutter();
      print("DEBUG: Hive.initFlutter done");
      
      // Register Adapters here (Generated adapters)
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FamilyMemberAdapter());
        print("DEBUG: FamilyMemberAdapter registered");
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(SurveyModelAdapter());
         print("DEBUG: SurveyModelAdapter registered");
      }
      // Hive.registerAdapter(UserModelAdapter()); // Uncomment when User model is ready
      
      await Hive.openBox<SurveyModel>(surveyBoxName);
      print("DEBUG: Hive box '$surveyBoxName' opened");
    } catch (e) {
      print("DEBUG: DatabaseService.init ERROR: $e");
      rethrow;
    }
  }

  // Get Survey Box
  Box<SurveyModel> get surveyBox => Hive.box<SurveyModel>(surveyBoxName);

  // Save Survey (Create or Update)
  Future<void> saveSurvey(SurveyModel survey) async {
    await surveyBox.put(survey.id, survey);
  }

  // Get All Surveys
  List<SurveyModel> getAllSurveys() {
    return surveyBox.values.toList();
  }

  // Delete Survey
  Future<void> deleteSurvey(String id) async {
    await surveyBox.delete(id);
  }

  // Clear All Data
  Future<void> clearAll() async {
    await surveyBox.clear();
  }
}
