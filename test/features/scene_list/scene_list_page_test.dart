import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_post_maker/data/project_repository.dart';
import 'package:fake_post_maker/data/scene_repository.dart';
import 'package:fake_post_maker/features/scene_list/scene_list_page.dart';
import 'package:fake_post_maker/models/project.dart';
import 'package:fake_post_maker/models/scene.dart';
import 'package:fake_post_maker/providers/project_providers.dart';
import 'package:fake_post_maker/providers/scene_providers.dart';

/// scene_repositoryと同様、projectRepositoryもHiveの実I/Oを避けるため
/// フェイクに差し替える(SceneListNotifierがScene追加/削除時に
/// projectListProviderをrefreshし、内部でProjectRepositoryへアクセスするため)。
class _FakeProjectRepository implements ProjectRepository {
  @override
  List<Project> getAll() => [];

  @override
  Future<void> add(Project project) async {}

  @override
  Future<void> update(Project project) async {}

  @override
  Future<void> delete(Project project) async {}
}

/// Hiveの実ディスクI/OはtestWidgetsのFakeAsyncゾーン内では待てないため、
/// Widgetテストではインメモリのフェイクリポジトリに差し替える(project_list_page_testと同じ方針)。
class _FakeSceneRepository implements SceneRepository {
  final Map<String, List<Scene>> _scenesByProjectId = {};

  @override
  List<Scene> getAll(Project project) {
    final scenes = List<Scene>.from(_scenesByProjectId[project.id] ?? []);
    return scenes..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Future<void> add(Project project, Scene scene) async {
    _scenesByProjectId.putIfAbsent(project.id, () => []).add(scene);
  }

  @override
  Future<void> update(Project project, Scene scene) async {
    final scenes = _scenesByProjectId[project.id];
    if (scenes == null) return;
    final index = scenes.indexWhere((s) => s.id == scene.id);
    if (index != -1) scenes[index] = scene;
  }

  @override
  Future<void> delete(Project project, String sceneId) async {
    _scenesByProjectId[project.id]?.removeWhere((s) => s.id == sceneId);
  }
}

void main() {
  late Project project;

  setUp(() {
    project = Project(
      id: 'project-1',
      name: 'テストプロジェクト',
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
  });

  Future<void> pumpSceneListPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sceneRepositoryProvider.overrideWithValue(_FakeSceneRepository()),
          projectRepositoryProvider.overrideWithValue(
            _FakeProjectRepository(),
          ),
        ],
        child: MaterialApp(home: SceneListPage(project: project)),
      ),
    );
  }

  testWidgets('Sceneが1件もない場合は空の状態メッセージが表示される', (tester) async {
    await pumpSceneListPage(tester);

    expect(find.textContaining('画面がありません'), findsOneWidget);
  });

  testWidgets('種類選択でタイムラインを選ぶと一覧に追加され、スワイプで削除すると空の状態に戻る', (
    tester,
  ) async {
    await pumpSceneListPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('タイムライン'), findsOneWidget);
    expect(find.text('投稿詳細'), findsOneWidget);

    await tester.tap(find.text('タイムライン'));
    await tester.pumpAndSettle();

    // タイムライン作成後はTimelineEditorPageへ自動遷移するため、一覧画面へ戻る
    expect(find.text('投稿がありません\n右下の + から追加してください'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 新規作成時のタイトルは種類ラベルと同じ文字列になるため、
    // ListTileのタイトル・サブタイトルの2箇所で見つかる
    expect(find.text('タイムライン'), findsNWidgets(2));
    expect(find.textContaining('画面がありません'), findsNothing);

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('タイムライン'), findsNothing);
    expect(find.textContaining('画面がありません'), findsOneWidget);
  });
}
