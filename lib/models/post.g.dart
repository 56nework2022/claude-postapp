// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PostAdapter extends TypeAdapter<Post> {
  @override
  final int typeId = 4;

  @override
  Post read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Post(
      id: fields[0] as String,
      accountId: fields[1] as String,
      body: fields[2] as String,
      likeCountLabel: fields[3] as String,
      repostCountLabel: fields[4] as String,
      replyCountLabel: fields[5] as String,
      postedAt: fields[6] as DateTime,
      order: fields[8] as int,
      quotedPostId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Post obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.accountId)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.likeCountLabel)
      ..writeByte(4)
      ..write(obj.repostCountLabel)
      ..writeByte(5)
      ..write(obj.replyCountLabel)
      ..writeByte(6)
      ..write(obj.postedAt)
      ..writeByte(7)
      ..write(obj.quotedPostId)
      ..writeByte(8)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
