import 'package:hive/hive.dart';

part 'status_bar_config.g.dart';

@HiveType(typeId: 6)
enum StatusBarPlatform {
  @HiveField(0)
  ios,
  @HiveField(1)
  android,
}

@HiveType(typeId: 7)
enum TimeMode {
  @HiveField(0)
  manual,
  @HiveField(1)
  current,
}

@HiveType(typeId: 5)
class StatusBarConfig {
  StatusBarConfig({
    required this.platform,
    required this.timeMode,
    required this.signalLevel,
    required this.batteryLevel,
    required this.isCharging,
    this.manualTime,
  });

  @HiveField(0)
  StatusBarPlatform platform;

  @HiveField(1)
  TimeMode timeMode;

  @HiveField(2)
  String? manualTime;

  @HiveField(3)
  int signalLevel;

  @HiveField(4)
  int batteryLevel;

  @HiveField(5)
  bool isCharging;
}
