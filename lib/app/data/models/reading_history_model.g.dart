// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReadingHistoryAdapter extends TypeAdapter<ReadingHistory> {
  @override
  final int typeId = 3;

  @override
  ReadingHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingHistory(
      id: fields[0] as String,
      storyId: fields[1] as String,
      storyTitle: fields[2] as String,
      storyAuthor: fields[3] as String,
      storyCoverUrl: fields[4] as String,
      chapterId: fields[5] as String?,
      chapterTitle: fields[6] as String?,
      chapterNumber: fields[7] as int?,
      readAt: fields[8] as DateTime?,
      readingDuration: fields[9] as int,
      scrollProgress: fields[10] as double,
      action: fields[11] as ReadingAction,
      sourceWebsite: fields[12] as String,
      metadata: (fields[13] as Map).cast<String, dynamic>(),
      sessionId: fields[14] as String,
      sessionStartAt: fields[15] as DateTime?,
      sessionEndAt: fields[16] as DateTime?,
      wordsRead: fields[17] as int,
      readingSpeed: fields[18] as double,
      deviceType: fields[19] as String,
      isOffline: fields[20] as bool,
      translationLanguage: fields[21] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingHistory obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.storyId)
      ..writeByte(2)
      ..write(obj.storyTitle)
      ..writeByte(3)
      ..write(obj.storyAuthor)
      ..writeByte(4)
      ..write(obj.storyCoverUrl)
      ..writeByte(5)
      ..write(obj.chapterId)
      ..writeByte(6)
      ..write(obj.chapterTitle)
      ..writeByte(7)
      ..write(obj.chapterNumber)
      ..writeByte(8)
      ..write(obj.readAt)
      ..writeByte(9)
      ..write(obj.readingDuration)
      ..writeByte(10)
      ..write(obj.scrollProgress)
      ..writeByte(11)
      ..write(obj.action)
      ..writeByte(12)
      ..write(obj.sourceWebsite)
      ..writeByte(13)
      ..write(obj.metadata)
      ..writeByte(14)
      ..write(obj.sessionId)
      ..writeByte(15)
      ..write(obj.sessionStartAt)
      ..writeByte(16)
      ..write(obj.sessionEndAt)
      ..writeByte(17)
      ..write(obj.wordsRead)
      ..writeByte(18)
      ..write(obj.readingSpeed)
      ..writeByte(19)
      ..write(obj.deviceType)
      ..writeByte(20)
      ..write(obj.isOffline)
      ..writeByte(21)
      ..write(obj.translationLanguage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReadingActionAdapter extends TypeAdapter<ReadingAction> {
  @override
  final int typeId = 4;

  @override
  ReadingAction read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReadingAction.read;
      case 1:
        return ReadingAction.addToLibrary;
      case 2:
        return ReadingAction.removeFromLibrary;
      case 3:
        return ReadingAction.favorite;
      case 4:
        return ReadingAction.unfavorite;
      case 5:
        return ReadingAction.rate;
      case 6:
        return ReadingAction.share;
      case 7:
        return ReadingAction.translate;
      case 8:
        return ReadingAction.download;
      case 9:
        return ReadingAction.view;
      default:
        return ReadingAction.read;
    }
  }

  @override
  void write(BinaryWriter writer, ReadingAction obj) {
    switch (obj) {
      case ReadingAction.read:
        writer.writeByte(0);
        break;
      case ReadingAction.addToLibrary:
        writer.writeByte(1);
        break;
      case ReadingAction.removeFromLibrary:
        writer.writeByte(2);
        break;
      case ReadingAction.favorite:
        writer.writeByte(3);
        break;
      case ReadingAction.unfavorite:
        writer.writeByte(4);
        break;
      case ReadingAction.rate:
        writer.writeByte(5);
        break;
      case ReadingAction.share:
        writer.writeByte(6);
        break;
      case ReadingAction.translate:
        writer.writeByte(7);
        break;
      case ReadingAction.download:
        writer.writeByte(8);
        break;
      case ReadingAction.view:
        writer.writeByte(9);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
