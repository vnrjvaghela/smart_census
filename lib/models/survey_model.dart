import 'package:hive/hive.dart';
import 'family_member_model.dart';

part 'survey_model.g.dart';

@HiveType(typeId: 2)
class SurveyModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String householdId;

  @HiveField(2)
  final String address;

  @HiveField(3)
  final double latitude;

  @HiveField(4)
  final double longitude;

  @HiveField(5)
  final List<FamilyMember> members;

  @HiveField(6)
  final List<String> documentPaths; // Local paths to images

  @HiveField(7)
  final bool isSynced;

  @HiveField(8)
  final String status; // 'Draft', 'Pending', 'Verified', 'Rejected'

  @HiveField(9)
  final DateTime timestamp;

  @HiveField(10)
  final bool aiVerified;

  @HiveField(11)
  final String blockchainHash;

  SurveyModel({
    required this.id,
    required this.householdId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.members,
    this.documentPaths = const [],
    this.isSynced = false,
    this.status = 'Draft',
    required this.timestamp,
    this.aiVerified = false,
    this.blockchainHash = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'householdId': householdId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'members': members.map((m) => m.toJson()).toList(),
      'documentPaths': documentPaths,
      'isSynced': isSynced,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'aiVerified': aiVerified,
      'blockchainHash': blockchainHash,
    };
  }

  factory SurveyModel.fromJson(Map<String, dynamic> json) {
    return SurveyModel(
      id: json['id'] ?? '',
      householdId: json['householdId'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      members: (json['members'] as List<dynamic>?)
          ?.map((e) => FamilyMember.fromJson(e))
          .toList() ?? [],
      documentPaths: List<String>.from(json['documentPaths'] ?? []),
      isSynced: json['isSynced'] ?? true, // Assume synced if coming from cloud
      status: json['status'] ?? 'Pending',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      aiVerified: json['aiVerified'] ?? false,
      blockchainHash: json['blockchainHash'] ?? '',
    );
  }
}
