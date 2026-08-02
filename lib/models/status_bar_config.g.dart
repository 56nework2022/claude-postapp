// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_bar_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StatusBarConfigAdapter extends TypeAdapter<StatusBarConfig> {
  @override
  final int typeId = 5;

  @override
  StatusBarConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StatusBarConfig(
      platform: fields[0] as StatusBarPlatform,
      timeMode: fields[1] as TimeMode,
      signalLevel: fields[3] as int,
      batteryLevel: fields[4] as int,
      isCharging: fields[5] as bool,
      manualTime: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, StatusBarConfig obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.platform)
      ..writeByte(1)
      ..write(obj.timeMode)
      ..writeByte(2)
      ..write(obj.manualTime)
      ..writeByte(3)
      ..write(obj.signalLevel)
      ..writeByte(4)
      ..write(obj.batteryLevel)
      ..writeByte(5)
      ..write(obj.isCharging);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatusBarConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StatusBarPlatformAdapter extends TypeAdapter<StatusBarPlatform> {
  @override
  final int typeId = 6;

  @override
  StatusBarPlatform read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return StatusBarPlatform.ios;
      case 1:
        return StatusBarPlatform.android;
      default:
        return StatusBarPlatform.ios;
    }
  }

  @override
  void write(BinaryWriter writer, StatusBarPlatform obj) {
    switch (obj) {
      case StatusBarPlatform.ios:
        writer.writeByte(0);
        break;
      case StatusBarPlatform.android:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatusBarPlatformAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TimeModeAdapter extends TypeAdapter<TimeMode> {
  @override
  final int typeId = 7;

  @override
  TimeMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TimeMode.manual;
      case 1:
        return TimeMode.current;
      default:
        return TimeMode.manual;
    }
  }

  @override
  void write(BinaryWriter writer, TimeMode obj) {
    switch (obj) {
      case TimeMode.manual:
        writer.writeByte(0);
        break;
      case TimeMode.current:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
