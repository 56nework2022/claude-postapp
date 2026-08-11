import 'package:hive_flutter/hive_flutter.dart';

import '../models/account.dart';
import '../models/post.dart';
import '../models/project.dart';
import '../models/scene.dart';
import '../models/status_bar_config.dart';

class HiveBoxes {
  HiveBoxes._();

  static const String projectsBoxName = 'projects';
  static const String appSettingsBoxName = 'app_settings';

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive
      ..registerAdapter(ProjectAdapter())
      ..registerAdapter(SceneAdapter())
      ..registerAdapter(SceneTypeAdapter())
      ..registerAdapter(AccountAdapter())
      ..registerAdapter(PostAdapter())
      ..registerAdapter(StatusBarConfigAdapter())
      ..registerAdapter(StatusBarPlatformAdapter())
      ..registerAdapter(TimeModeAdapter());

    await Hive.openBox<Project>(projectsBoxName);
    await Hive.openBox(appSettingsBoxName);
  }

  static Box<Project> get projectsBox => Hive.box<Project>(projectsBoxName);
  static Box get appSettingsBox => Hive.box(appSettingsBoxName);
}
