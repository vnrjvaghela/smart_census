import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:smart_census/models/survey_model.dart';

class CryptoUtils {
  /// Generates a SHA-256 hash representative of the survey data.
  /// In a production environment, this exact hash string would be stored
  /// on a blockchain (Ethereum/Hyperledger) to prove data immutability.
  static String generateSurveyHash(SurveyModel survey) {
    // We create a deterministic string out of the core data
    final dataString = "${survey.householdId}|${survey.address}|"
        "${survey.latitude}|${survey.longitude}|"
        "${survey.members.length}|${survey.timestamp.toIso8601String()}";

    // Standard UTF-8 encode followed by standard SHA-256 hash
    final bytes = utf8.encode(dataString);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }
}
