// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_conversation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatConversationAdapter extends TypeAdapter<ChatConversation> {
  @override
  final int typeId = 13;

  @override
  ChatConversation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatConversation(
      id: fields[0] as String,
      title: fields[1] as String,
      createdAt: fields[2] as DateTime?,
      updatedAt: fields[3] as DateTime?,
      messageIds: (fields[4] as List).cast<String>(),
      metadata: (fields[5] as Map).cast<String, dynamic>(),
      systemPrompt: fields[6] as String?,
      isPinned: fields[7] as bool,
      lastMessagePreview: fields[8] as String?,
      messageCount: fields[9] as int,
      status: fields[10] as ConversationStatus,
    );
  }

  @override
  void write(BinaryWriter writer, ChatConversation obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.messageIds)
      ..writeByte(5)
      ..write(obj.metadata)
      ..writeByte(6)
      ..write(obj.systemPrompt)
      ..writeByte(7)
      ..write(obj.isPinned)
      ..writeByte(8)
      ..write(obj.lastMessagePreview)
      ..writeByte(9)
      ..write(obj.messageCount)
      ..writeByte(10)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatConversationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConversationStatusAdapter extends TypeAdapter<ConversationStatus> {
  @override
  final int typeId = 14;

  @override
  ConversationStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ConversationStatus.active;
      case 1:
        return ConversationStatus.archived;
      case 2:
        return ConversationStatus.deleted;
      default:
        return ConversationStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, ConversationStatus obj) {
    switch (obj) {
      case ConversationStatus.active:
        writer.writeByte(0);
        break;
      case ConversationStatus.archived:
        writer.writeByte(1);
        break;
      case ConversationStatus.deleted:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
