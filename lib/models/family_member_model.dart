import 'package:hive/hive.dart';

part 'family_member_model.g.dart';

@HiveType(typeId: 1)
class FamilyMember {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int age;

  @HiveField(3)
  final String gender;

  @HiveField(4)
  final String relation; // Head, Spouse, Child, etc.

  @HiveField(5)
  final String education;

  @HiveField(6)
  final String occupation;

  @HiveField(7)
  final String caste;

  @HiveField(8)
  final String subCaste;

  FamilyMember({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.relation,
    this.education = '',
    this.occupation = '',
    required this.caste,
    this.subCaste = '',
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      relation: json['relation'] ?? '',
      education: json['education'] ?? '',
      occupation: json['occupation'] ?? '',
      caste: json['caste'] ?? '',
      subCaste: json['subCaste'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'relation': relation,
      'education': education,
      'occupation': occupation,
      'caste': caste,
      'subCaste': subCaste,
    };
  }
}
