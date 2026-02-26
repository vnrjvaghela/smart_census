// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_member_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FamilyMemberAdapter extends TypeAdapter<FamilyMember> {
  @override
  final int typeId = 1;

  @override
  FamilyMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FamilyMember(
      id: fields[0] as String,
      name: fields[1] as String,
      age: fields[2] as int,
      gender: fields[3] as String,
      relation: fields[4] as String,
      education: fields[5] as String,
      occupation: fields[6] as String,
      caste: fields[7] as String,
      subCaste: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FamilyMember obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.gender)
      ..writeByte(4)
      ..write(obj.relation)
      ..writeByte(5)
      ..write(obj.education)
      ..writeByte(6)
      ..write(obj.occupation)
      ..writeByte(7)
      ..write(obj.caste)
      ..writeByte(8)
      ..write(obj.subCaste);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FamilyMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
