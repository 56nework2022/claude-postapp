import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_post_maker/data/project_repository.dart';
import 'package:fake_post_maker/data/scene_repository.dart';
import 'package:fake_post_maker/features/project_list/project_list_page.dart';
import 'package:fake_post_maker/models/project.dart';
import 'package:fake_post_maker/models/scene.dart';
import 'package:fake_post_maker/providers/project_providers.dart';
import 'package:fake_post_maker/providers/scene_providers.dart';

/// Hiveの実ディスクI/Oは`testWidgets`が使うFakeAsyncゾーン内では
/// 完了を待てず永久に固まるため、Widgetテストではインメモリの
/// フェイクリポジトリに差し替える(実際のHive永続化は`test/data/`で検証済み)。
class _FakeProjectRepository implements ProjectRepository {
  final List<Project> _projects = [];

  @override
  List<Project> getAll() => List.unmodifiable(_projects);

  @override
  Future<void> add(Project project) async {
    _projects.add(project);
  }

  @override
  Future<void> update(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index == -1) return;
    project.updatedAt = DateTime.now();
    _projects[index] = project;
  }

  @override
  Future<void> delete(Project project) async {
    _projects.removeWhere((p) => p.id == project.id);
  }
}

/// scene_list_page_testと同じ方針で、Hiveの実I/Oを避けるためのフェイク。
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
    project.scenes.add(scene);
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
    project.scenes.removeWhere((s) => s.id == sceneId);
  }
}

void main() {
  Future<void> pumpProjectListPage(
    WidgetTester tester, {
    SceneRepository? sceneRepository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectRepositoryProvider.overrideWithValue(
            _FakeProjectRepository(),
          ),
          sceneRepositoryProvider.overrideWithValue(
            sceneRepository ?? _FakeSceneRepository(),
          ),
        ],
        child: const MaterialApp(home: ProjectListPage()),
      ),
    );
  }

  testWidgets('プロジェクトが1件もない場合は空の状態メッセージが表示される', (tester) async {
    await pumpProjectListPage(tester);

    expect(find.textContaining('プロジェクトがありません'), findsOneWidget);
  });

  testWidgets('新規作成すると一覧に追加され、スワイプで削除すると再び空の状態に戻る', (tester) async {
    await pumpProjectListPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'テストプロジェクト');
    await tester.tap(find.widgetWithText(TextButton, '作成'));
    await tester.pumpAndSettle();

    expect(find.text('テストプロジェクト'), findsOneWidget);
    expect(find.textContaining('プロジェクトがありません'), findsNothing);

    await tester.drag(find.text('テストプロジェクト'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('テストプロジェクト'), findsNothing);
    expect(find.textContaining('プロジェクトがありません'), findsOneWidget);
  });

  testWidgets('編集アイコンからプロジェクト名を変更できる', (tester) async {
    await pumpProjectListPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'テストプロジェクト');
    await tester.tap(find.widgetWithText(TextButton, '作成'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'テストプロジェクト'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '改名後プロジェクト');
    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('改名後プロジェクト'), findsOneWidget);
    expect(find.text('テストプロジェクト'), findsNothing);
  });

  testWidgets('プロジェクトをタップすると画面(Scene)一覧画面へ遷移する', (tester) async {
    await pumpProjectListPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'テストプロジェクト');
    await tester.tap(find.widgetWithText(TextButton, '作成'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('テストプロジェクト'));
    await tester.pumpAndSettle();

    expect(find.text('画面がありません\n右下の + から作成してください'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'テストプロジェクト'), findsOneWidget);
  });

  testWidgets('画面(Scene)を追加して一覧に戻ると画面数の表示が更新される', (tester) async {
    await pumpProjectListPage(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'テストプロジェクト');
    await tester.tap(find.widgetWithText(TextButton, '作成'));
    await tester.pumpAndSettle();

    expect(find.text('画面数: 0'), findsOneWidget);

    await tester.tap(find.text('テストプロジェクト'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('タイムライン'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('画面数: 1'), findsOneWidget);
  });
}
