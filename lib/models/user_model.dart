import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String phoneNumber;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String district;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    this.name = '',
    this.district = '',
  });

  // Factory constructor to create a UserModel from JSON (Firebase)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      name: json['name'] ?? '',
      district: json['district'] ?? '',
    );
  }

  // Method to convert UserModel to JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': name,
      'district': district,
    };
  }
}
