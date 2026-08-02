import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:fake_x_post_maker/data/hive_boxes.dart';
import 'package:fake_x_post_maker/data/project_repository.dart';
import 'package:fake_x_post_maker/data/scene_repository.dart';
import 'package:fake_x_post_maker/models/project.dart';
import 'package:fake_x_post_maker/models/scene.dart';
import 'package:fake_x_post_maker/models/status_bar_config.dart';

import '../hive_test_utils.dart';

StatusBarConfig _buildStatusBarConfig() {
  return StatusBarConfig(
    platform: StatusBarPlatform.ios,
    timeMode: TimeMode.current,
    signalLevel: 4,
    batteryLevel: 100,
    isCharging: false,
  );
}

void main() {
  late Project project;

  setUp(() async {
    await setUpHiveForTest();
    await Hive.openBox<Project>(HiveBoxes.projectsBoxName);
    project = Project(
      id: 'project-1',
      name: 'テストプロジェクト',
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
    await ProjectRepository().add(project);
  });
  tearDown(tearDownHiveForTest);

  test('Sceneを追加するとProjectのScene一覧に反映され、orderの昇順で取得できる', () async {
    final repository = SceneRepository();
    final sceneA = Scene(
      id: 'scene-a',
      projectId: project.id,
      type: SceneType.timeline,
      title: 'タイムラインA',
      order: 1,
      statusBarConfig: _buildStatusBarConfig(),
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
    final sceneB = Scene(
      id: 'scene-b',
      projectId: project.id,
      type: SceneType.postDetail,
      title: '投稿詳細B',
      order: 0,
      statusBarConfig: _buildStatusBarConfig(),
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );

    await repository.add(project, sceneA);
    await repository.add(project, sceneB);

    final scenes = repository.getAll(project);
    expect(scenes, hasLength(2));
    expect(scenes.first.id, 'scene-b');
  });

  test('Sceneを更新すると該当Sceneの内容が置き換わる', () async {
    final repository = SceneRepository();
    final scene = Scene(
      id: 'scene-a',
      projectId: project.id,
      type: SceneType.timeline,
      title: '旧タイトル',
      order: 0,
      statusBarConfig: _buildStatusBarConfig(),
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
    await repository.add(project, scene);

    final updatedScene = Scene(
      id: 'scene-a',
      projectId: project.id,
      type: SceneType.timeline,
      title: '新タイトル',
      order: 0,
      statusBarConfig: _buildStatusBarConfig(),
      createdAt: scene.createdAt,
      updatedAt: DateTime(2026, 8, 1),
    );
    await repository.update(project, updatedScene);

    expect(repository.getAll(project).first.title, '新タイトル');
  });

  test('Sceneを削除すると一覧から取り除かれる', () async {
    final repository = SceneRepository();
    final scene = Scene(
      id: 'scene-a',
      projectId: project.id,
      type: SceneType.timeline,
      title: 'タイムライン',
      order: 0,
      statusBarConfig: _buildStatusBarConfig(),
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
    await repository.add(project, scene);

    await repository.delete(project, scene.id);

    expect(repository.getAll(project), isEmpty);
  });
}
