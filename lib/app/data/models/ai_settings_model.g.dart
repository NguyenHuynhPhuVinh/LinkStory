// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AiSettingsAdapter extends TypeAdapter<AiSettings> {
  @override
  final int typeId = 15;

  @override
  AiSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AiSettings(
      modelName: fields[0] as String,
      systemPrompt: fields[1] as String,
      temperature: fields[2] as double,
      topP: fields[3] as double,
      topK: fields[4] as int,
      maxOutputTokens: fields[5] as int,
      safetySettings: (fields[6] as List).cast<String>(),
      enableStreaming: fields[7] as bool,
      enableMarkdown: fields[8] as bool,
      language: fields[9] as String,
      createdAt: fields[10] as DateTime,
      updatedAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AiSettings obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.modelName)
      ..writeByte(1)
      ..write(obj.systemPrompt)
      ..writeByte(2)
      ..write(obj.temperature)
      ..writeByte(3)
      ..write(obj.topP)
      ..writeByte(4)
      ..write(obj.topK)
      ..writeByte(5)
      ..write(obj.maxOutputTokens)
      ..writeByte(6)
      ..write(obj.safetySettings)
      ..writeByte(7)
      ..write(obj.enableStreaming)
      ..writeByte(8)
      ..write(obj.enableMarkdown)
      ..writeByte(9)
      ..write(obj.language)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
