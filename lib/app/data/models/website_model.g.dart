// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'website_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WebsiteAdapter extends TypeAdapter<Website> {
  @override
  final int typeId = 0;

  @override
  Website read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Website(
      id: fields[0] as String,
      name: fields[1] as String,
      url: fields[2] as String,
      iconUrl: fields[3] as String,
      description: fields[4] as String,
      isActive: fields[5] as bool,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Website obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.url)
      ..writeByte(3)
      ..write(obj.iconUrl)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WebsiteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
