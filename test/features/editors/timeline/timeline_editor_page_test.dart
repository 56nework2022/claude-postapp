import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_x_post_maker/data/scene_repository.dart';
import 'package:fake_x_post_maker/features/editors/timeline/timeline_editor_page.dart';
import 'package:fake_x_post_maker/models/project.dart';
import 'package:fake_x_post_maker/models/scene.dart';
import 'package:fake_x_post_maker/models/status_bar_config.dart';
import 'package:fake_x_post_maker/providers/scene_providers.dart';
import 'package:fake_x_post_maker/widgets/post_card.dart';

/// Hiveの実ディスクI/OはtestWidgetsのFakeAsyncゾーン内では待てないため、
/// Widgetテストではインメモリのフェイクリポジトリに差し替える
/// (post_detail_editor_page_testと同じ方針)。
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
  late Scene scene;
  late _FakeSceneRepository repository;

  setUp(() async {
    project = Project(
      id: 'project-1',
      name: 'テストプロジェクト',
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
    scene = Scene(
      id: 'scene-1',
      projectId: project.id,
      type: SceneType.timeline,
      title: 'タイムライン',
      order: 0,
      statusBarConfig: StatusBarConfig(
        platform: StatusBarPlatform.ios,
        timeMode: TimeMode.current,
        signalLevel: 4,
        batteryLevel: 100,
        isCharging: false,
      ),
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
    repository = _FakeSceneRepository();
    await repository.add(project, scene);
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sceneRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: TimelineEditorPage(project: project, scene: scene),
        ),
      ),
    );
  }

  testWidgets('投稿が1件もない場合は空の状態メッセージが表示される', (tester) async {
    await pumpPage(tester);

    expect(find.textContaining('投稿がありません'), findsOneWidget);
  });

  testWidgets('+ボタンで投稿を追加するとPostCardが一覧に表示され保存される', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.textContaining('投稿がありません'), findsNothing);
    expect(find.byType(PostCard), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(PostCard), findsNWidgets(2));

    final savedScene = repository.getAll(project).single;
    expect(savedScene.posts.length, 2);
  });

  testWidgets('投稿をタップすると編集シートが開き、本文の変更が保存される', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // ReorderableListViewはアイテムをOverlay経由で描画するため、
    // 標準のヒットテスト検証が誤警告を出す(機能的には問題ない既知の挙動)。
    await tester.tap(find.byType(PostCard), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('投稿を編集'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '本文'), 'テスト投稿');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '閉じる'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(PostCard),
        matching: find.text('テスト投稿'),
      ),
      findsOneWidget,
    );

    final savedScene = repository.getAll(project).single;
    expect(savedScene.posts.single.body, 'テスト投稿');
  });

  testWidgets('削除ボタンで投稿を削除すると一覧から消え保存される', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(PostCard), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.byType(PostCard), findsNothing);
    expect(find.textContaining('投稿がありません'), findsOneWidget);

    final savedScene = repository.getAll(project).single;
    expect(savedScene.posts, isEmpty);
  });
}
