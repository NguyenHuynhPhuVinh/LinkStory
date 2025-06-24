// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoryAdapter extends TypeAdapter<Story> {
  @override
  final int typeId = 1;

  @override
  Story read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Story(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      description: fields[3] as String,
      coverImageUrl: fields[4] as String,
      sourceUrl: fields[5] as String,
      sourceWebsite: fields[6] as String,
      genres: (fields[7] as List).cast<String>(),
      status: fields[8] as String,
      totalChapters: fields[9] as int,
      readChapters: fields[10] as int,
      createdAt: fields[11] as DateTime?,
      updatedAt: fields[12] as DateTime?,
      lastReadAt: fields[13] as DateTime?,
      isFavorite: fields[14] as bool,
      rating: fields[15] as double,
      translator: fields[16] as String,
      originalLanguage: fields[17] as String,
      metadata: (fields[18] as Map).cast<String, dynamic>(),
      translatedTitle: fields[19] as String?,
      translatedAuthor: fields[20] as String?,
      translatedDescription: fields[21] as String?,
      translatedGenres: (fields[22] as List?)?.cast<String>(),
      isTranslated: fields[23] as bool,
      translatedAt: fields[24] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Story obj) {
    writer
      ..writeByte(25)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.coverImageUrl)
      ..writeByte(5)
      ..write(obj.sourceUrl)
      ..writeByte(6)
      ..write(obj.sourceWebsite)
      ..writeByte(7)
      ..write(obj.genres)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.totalChapters)
      ..writeByte(10)
      ..write(obj.readChapters)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.lastReadAt)
      ..writeByte(14)
      ..write(obj.isFavorite)
      ..writeByte(15)
      ..write(obj.rating)
      ..writeByte(16)
      ..write(obj.translator)
      ..writeByte(17)
      ..write(obj.originalLanguage)
      ..writeByte(18)
      ..write(obj.metadata)
      ..writeByte(19)
      ..write(obj.translatedTitle)
      ..writeByte(20)
      ..write(obj.translatedAuthor)
      ..writeByte(21)
      ..write(obj.translatedDescription)
      ..writeByte(22)
      ..write(obj.translatedGenres)
      ..writeByte(23)
      ..write(obj.isTranslated)
      ..writeByte(24)
      ..write(obj.translatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
