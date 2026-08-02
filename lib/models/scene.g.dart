// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scene.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SceneAdapter extends TypeAdapter<Scene> {
  @override
  final int typeId = 1;

  @override
  Scene read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Scene(
      id: fields[0] as String,
      projectId: fields[1] as String,
      type: fields[2] as SceneType,
      title: fields[3] as String,
      order: fields[4] as int,
      statusBarConfig: fields[5] as StatusBarConfig,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      accounts: (fields[6] as List?)?.cast<Account>(),
      posts: (fields[7] as List?)?.cast<Post>(),
    );
  }

  @override
  void write(BinaryWriter writer, Scene obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.order)
      ..writeByte(5)
      ..write(obj.statusBarConfig)
      ..writeByte(6)
      ..write(obj.accounts)
      ..writeByte(7)
      ..write(obj.posts)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SceneTypeAdapter extends TypeAdapter<SceneType> {
  @override
  final int typeId = 2;

  @override
  SceneType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SceneType.timeline;
      case 1:
        return SceneType.postDetail;
      case 2:
        return SceneType.profile;
      case 3:
        return SceneType.dm;
      default:
        return SceneType.timeline;
    }
  }

  @override
  void write(BinaryWriter writer, SceneType obj) {
    switch (obj) {
      case SceneType.timeline:
        writer.writeByte(0);
        break;
      case SceneType.postDetail:
        writer.writeByte(1);
        break;
      case SceneType.profile:
        writer.writeByte(2);
        break;
      case SceneType.dm:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SceneTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
