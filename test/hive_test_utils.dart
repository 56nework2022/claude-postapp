import 'dart:io';

import 'package:hive/hive.dart';

import 'package:fake_post_maker/models/account.dart';
import 'package:fake_post_maker/models/post.dart';
import 'package:fake_post_maker/models/project.dart';
import 'package:fake_post_maker/models/scene.dart';
import 'package:fake_post_maker/models/status_bar_config.dart';

Directory? _tempDir;

Future<void> setUpHiveForTest() async {
  _tempDir = await Directory.systemTemp.createTemp('hive_test_');
  Hive.init(_tempDir!.path);

  if (!Hive.isAdapterRegistered(0)) {
    Hive
      ..registerAdapter(ProjectAdapter())
      ..registerAdapter(SceneAdapter())
      ..registerAdapter(SceneTypeAdapter())
      ..registerAdapter(AccountAdapter())
      ..registerAdapter(PostAdapter())
      ..registerAdapter(StatusBarConfigAdapter())
      ..registerAdapter(StatusBarPlatformAdapter())
      ..registerAdapter(TimeModeAdapter());
  }
}

Future<void> tearDownHiveForTest() async {
  await Hive.deleteFromDisk();
  final dir = _tempDir;
  if (dir != null && dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
}
