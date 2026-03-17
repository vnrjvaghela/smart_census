// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'survey_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SurveyModelAdapter extends TypeAdapter<SurveyModel> {
  @override
  final int typeId = 2;

  @override
  SurveyModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SurveyModel(
      id: fields[0] as String,
      householdId: fields[1] as String,
      address: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      members: (fields[5] as List).cast<FamilyMember>(),
      documentPaths: (fields[6] as List).cast<String>(),
      isSynced: fields[7] as bool,
      status: fields[8] as String,
      timestamp: fields[9] as DateTime,
      aiVerified: fields[10] as bool,
      blockchainHash: fields[11] as String,
      documentUrls: (fields[12] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, SurveyModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.householdId)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.members)
      ..writeByte(6)
      ..write(obj.documentPaths)
      ..writeByte(7)
      ..write(obj.isSynced)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.timestamp)
      ..writeByte(10)
      ..write(obj.aiVerified)
      ..writeByte(11)
      ..write(obj.blockchainHash)
      ..writeByte(12)
      ..write(obj.documentUrls);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurveyModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
