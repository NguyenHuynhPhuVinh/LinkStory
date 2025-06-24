// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 10;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      id: fields[0] as String,
      conversationId: fields[1] as String,
      content: fields[2] as String,
      role: fields[3] as ChatMessageRole,
      timestamp: fields[4] as DateTime,
      status: fields[5] as ChatMessageStatus,
      metadata: (fields[6] as Map).cast<String, dynamic>(),
      isMarkdown: fields[7] as bool,
      attachments: (fields[8] as List).cast<String>(),
      errorMessage: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.conversationId)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.metadata)
      ..writeByte(7)
      ..write(obj.isMarkdown)
      ..writeByte(8)
      ..write(obj.attachments)
      ..writeByte(9)
      ..write(obj.errorMessage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatMessageRoleAdapter extends TypeAdapter<ChatMessageRole> {
  @override
  final int typeId = 11;

  @override
  ChatMessageRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChatMessageRole.user;
      case 1:
        return ChatMessageRole.assistant;
      case 2:
        return ChatMessageRole.system;
      default:
        return ChatMessageRole.user;
    }
  }

  @override
  void write(BinaryWriter writer, ChatMessageRole obj) {
    switch (obj) {
      case ChatMessageRole.user:
        writer.writeByte(0);
        break;
      case ChatMessageRole.assistant:
        writer.writeByte(1);
        break;
      case ChatMessageRole.system:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatMessageStatusAdapter extends TypeAdapter<ChatMessageStatus> {
  @override
  final int typeId = 12;

  @override
  ChatMessageStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ChatMessageStatus.sending;
      case 1:
        return ChatMessageStatus.sent;
      case 2:
        return ChatMessageStatus.delivered;
      case 3:
        return ChatMessageStatus.failed;
      case 4:
        return ChatMessageStatus.streaming;
      default:
        return ChatMessageStatus.sending;
    }
  }

  @override
  void write(BinaryWriter writer, ChatMessageStatus obj) {
    switch (obj) {
      case ChatMessageStatus.sending:
        writer.writeByte(0);
        break;
      case ChatMessageStatus.sent:
        writer.writeByte(1);
        break;
      case ChatMessageStatus.delivered:
        writer.writeByte(2);
        break;
      case ChatMessageStatus.failed:
        writer.writeByte(3);
        break;
      case ChatMessageStatus.streaming:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
