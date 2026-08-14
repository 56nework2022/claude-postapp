import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scene_repository.dart';
import '../models/project.dart';
import '../models/scene.dart';
import '../models/status_bar_config.dart';
import 'project_providers.dart';

final sceneRepositoryProvider = Provider<SceneRepository>((ref) {
  return SceneRepository();
});

final sceneListProvider =
    NotifierProvider.family<SceneListNotifier, List<Scene>, Project>(
      SceneListNotifier.new,
    );

class SceneListNotifier extends FamilyNotifier<List<Scene>, Project> {
  @override
  List<Scene> build(Project arg) {
    return ref.read(sceneRepositoryProvider).getAll(arg);
  }

  Future<Scene> createScene({
    required String title,
    required SceneType type,
  }) async {
    final repository = ref.read(sceneRepositoryProvider);
    final now = DateTime.now();
    final scene = Scene(
      id: _generateId(),
      projectId: arg.id,
      type: type,
      title: title,
      order: state.length,
      statusBarConfig: StatusBarConfig(
        platform: StatusBarPlatform.ios,
        timeMode: TimeMode.current,
        signalLevel: 4,
        batteryLevel: 100,
        isCharging: false,
      ),
      createdAt: now,
      updatedAt: now,
    );
    await repository.add(arg, scene);
    state = repository.getAll(arg);
    ref.read(projectListProvider.notifier).refresh();
    return scene;
  }

  Future<void> deleteScene(Scene scene) async {
    final repository = ref.read(sceneRepositoryProvider);
    await repository.delete(arg, scene.id);
    state = repository.getAll(arg);
    ref.read(projectListProvider.notifier).refresh();
  }

  String _generateId() {
    final randomSuffix = Random().nextInt(1 << 32).toRadixString(16);
    return '${DateTime.now().microsecondsSinceEpoch}-$randomSuffix';
  }
}
