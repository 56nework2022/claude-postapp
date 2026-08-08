import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_post_maker/data/scene_repository.dart';
import 'package:fake_post_maker/features/editors/post_detail/post_detail_editor_page.dart';
import 'package:fake_post_maker/models/project.dart';
import 'package:fake_post_maker/models/scene.dart';
import 'package:fake_post_maker/models/status_bar_config.dart';
import 'package:fake_post_maker/providers/scene_providers.dart';
import 'package:fake_post_maker/widgets/post_card.dart';
import 'package:fake_post_maker/widgets/post_editor_sheet.dart';

/// Hiveの実ディスクI/OはtestWidgetsのFakeAsyncゾーン内では待てないため、
/// Widgetテストではインメモリのフェイクリポジトリに差し替える
/// (project_list_page_test・scene_list_page_testと同じ方針)。
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
      type: SceneType.postDetail,
      title: '投稿詳細',
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
          home: PostDetailEditorPage(project: project, scene: scene),
        ),
      ),
    );
  }

  testWidgets('初期状態でデフォルトのアカウント・投稿が生成されプレビューに表示される', (tester) async {
    await pumpPage(tester);

    expect(find.byType(PostCard), findsOneWidget);
    expect(find.textContaining('表示名'), findsWidgets);
    expect(find.textContaining('@username'), findsWidgets);
  });

  testWidgets('本文を入力するとプレビューにリアルタイムで反映され、保存される', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.widgetWithText(TextField, '本文'), 'こんにちは');
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(PostCard),
        matching: find.text('こんにちは'),
      ),
      findsOneWidget,
    );

    final savedScene = repository.getAll(project).single;
    expect(savedScene.posts.single.body, 'こんにちは');
  });

  testWidgets('引用ポストを追加するとプレビューに入れ子表示され、保存される', (tester) async {
    await pumpPage(tester);

    expect(find.byType(PostCard), findsOneWidget);

    // SwitchListTileはListView仮想化により初期表示範囲外にあるためスクロールしてから操作する
    await tester.dragUntilVisible(
      find.byType(SwitchListTile),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // 追加されたセクションもListView仮想化の範囲外にあり得るため、再度スクロールする
    await tester.dragUntilVisible(
      find.text('引用元アカウント設定'),
      find.byType(ListView),
      const Offset(0, -300),
    );

    expect(find.text('引用元アカウント設定'), findsOneWidget);
    expect(find.byType(PostCard), findsNWidgets(2));

    final savedScene = repository.getAll(project).single;
    expect(savedScene.posts.length, 2);
    expect(savedScene.posts.firstWhere((p) => p.order == 0).quotedPostId, isNotNull);

    await tester.dragUntilVisible(
      find.byType(SwitchListTile),
      find.byType(ListView),
      const Offset(0, 300),
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('引用元アカウント設定'), findsNothing);
    expect(find.byType(PostCard), findsOneWidget);
  });

  testWidgets('リプライを追加するとプレビュー・一覧に表示され、保存される', (tester) async {
    await pumpPage(tester);

    await tester.dragUntilVisible(
      find.widgetWithText(TextButton, 'リプライを追加'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.widgetWithText(TextButton, 'リプライを追加'));
    await tester.pumpAndSettle();

    // 一覧内タイルはListView仮想化により初期表示範囲外にあり得るためスクロールする
    final replyTilePostCard = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.byType(PostCard),
    );
    await tester.dragUntilVisible(
      replyTilePostCard,
      find.byType(ListView),
      const Offset(0, -300),
    );

    // メインのプレビュー・リプライのプレビュー・一覧内タイルの3件表示される
    expect(find.byType(PostCard), findsNWidgets(3));

    final savedScene = repository.getAll(project).single;
    expect(savedScene.posts.length, 2);
    expect(savedScene.posts.firstWhere((p) => p.order == 2), isNotNull);
  });

  testWidgets('リプライをタップして本文を編集すると保存される', (tester) async {
    await pumpPage(tester);

    await tester.dragUntilVisible(
      find.widgetWithText(TextButton, 'リプライを追加'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.widgetWithText(TextButton, 'リプライを追加'));
    await tester.pumpAndSettle();

    final replyId = repository
        .getAll(project)
        .single
        .posts
        .firstWhere((p) => p.order == 2)
        .id;

    final replyTilePostCard = find.descendant(
      of: find.byType(ReorderableListView),
      matching: find.byType(PostCard),
    );
    await tester.dragUntilVisible(
      replyTilePostCard,
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(replyTilePostCard, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('投稿を編集'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(PostEditorSheet),
        matching: find.widgetWithText(TextField, '本文'),
      ),
      'リプライ本文',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '閉じる'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(PostCard),
        matching: find.text('リプライ本文'),
      ),
      findsWidgets,
    );

    final savedScene = repository.getAll(project).single;
    expect(
      savedScene.posts.firstWhere((p) => p.id == replyId).body,
      'リプライ本文',
    );
  });

  testWidgets('削除ボタンでリプライを削除すると一覧・プレビューから消え、保存される', (tester) async {
    await pumpPage(tester);

    await tester.dragUntilVisible(
      find.widgetWithText(TextButton, 'リプライを追加'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.widgetWithText(TextButton, 'リプライを追加'));
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.byIcon(Icons.delete_outline),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.byType(PostCard), findsOneWidget);

    final savedScene = repository.getAll(project).single;
    expect(savedScene.posts.length, 1);
  });
}
