import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_post_maker/data/scene_repository.dart';
import 'package:fake_post_maker/models/project.dart';
import 'package:fake_post_maker/models/scene.dart';
import 'package:fake_post_maker/models/status_bar_config.dart';
import 'package:fake_post_maker/providers/editor_providers.dart';
import 'package:fake_post_maker/providers/scene_providers.dart';

/// Hiveの実ディスクI/Oを使わず、インメモリでSceneRepositoryの挙動を再現する
/// (Widgetテストで使っているフェイクと同じ方針。ここではWidgetを介さない
/// Notifierロジックの検証に使う)。
class _FakeSceneRepository implements SceneRepository {
  final Map<String, List<Scene>> _scenesByProjectId = {};

  @override
  List<Scene> getAll(Project project) =>
      List<Scene>.from(_scenesByProjectId[project.id] ?? []);

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
  late ProviderContainer container;

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

    container = ProviderContainer(
      overrides: [sceneRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  SceneEditorArg buildArg() => (project: project, scene: scene);

  test('addPostは投稿とアカウントを1件ずつ追加し、orderを末尾に振る', () async {
    final arg = buildArg();
    final notifier = container.read(timelineEditorProvider(arg).notifier);

    await notifier.addPost();
    await notifier.addPost();

    final state = container.read(timelineEditorProvider(arg));
    expect(state.posts.length, 2);
    expect(state.accounts.length, 2);
    expect(state.posts.map((p) => p.order).toList()..sort(), [0, 1]);

    final saved = repository.getAll(project).single;
    expect(saved.posts.length, 2);
  });

  test('deletePostは対象の投稿・アカウントを削除しorderを詰め直す', () async {
    final arg = buildArg();
    final notifier = container.read(timelineEditorProvider(arg).notifier);
    await notifier.addPost();
    await notifier.addPost();
    await notifier.addPost();

    final state = container.read(timelineEditorProvider(arg));
    final target = state.posts.firstWhere((p) => p.order == 1);

    await notifier.deletePost(target);

    final after = container.read(timelineEditorProvider(arg));
    expect(after.posts.length, 2);
    expect(after.accounts.length, 2);
    expect(
      after.posts.map((p) => p.order).toList()..sort(),
      [0, 1],
    );
    expect(after.posts.any((p) => p.id == target.id), isFalse);
  });

  test('reorderPostは指定した位置に投稿を移動しorderを振り直す', () async {
    final arg = buildArg();
    final notifier = container.read(timelineEditorProvider(arg).notifier);
    await notifier.addPost();
    await notifier.addPost();
    await notifier.addPost();

    final before = container.read(timelineEditorProvider(arg));
    final sorted = List.of(before.posts)
      ..sort((a, b) => a.order.compareTo(b.order));
    final firstId = sorted[0].id;

    // 先頭の投稿を末尾(index 2)へ移動する
    await notifier.reorderPost(0, 2);

    final after = container.read(timelineEditorProvider(arg));
    final afterSorted = List.of(after.posts)
      ..sort((a, b) => a.order.compareTo(b.order));
    expect(afterSorted.last.id, firstId);
    expect(afterSorted.map((p) => p.order).toList(), [0, 1, 2]);
  });

  group('PostDetailEditorNotifier - リプライ', () {
    late Project detailProject;
    late Scene detailScene;
    late _FakeSceneRepository detailRepository;
    late ProviderContainer detailContainer;

    setUp(() async {
      detailProject = Project(
        id: 'project-2',
        name: '投稿詳細テストプロジェクト',
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );
      detailScene = Scene(
        id: 'scene-2',
        projectId: detailProject.id,
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
      detailRepository = _FakeSceneRepository();
      await detailRepository.add(detailProject, detailScene);

      detailContainer = ProviderContainer(
        overrides: [
          sceneRepositoryProvider.overrideWithValue(detailRepository),
        ],
      );
      addTearDown(detailContainer.dispose);
    });

    SceneEditorArg buildDetailArg() =>
        (project: detailProject, scene: detailScene);

    test('repliesOfはorder2以上の投稿をorder昇順で返す', () async {
      final arg = buildDetailArg();
      final notifier = detailContainer.read(
        postDetailEditorProvider(arg).notifier,
      );
      // build()でメイン投稿(order:0)が生成される
      detailContainer.read(postDetailEditorProvider(arg));

      await notifier.addReply();
      await notifier.addReply();

      final state = detailContainer.read(postDetailEditorProvider(arg));
      final replies = repliesOf(state);
      expect(replies.map((p) => p.order).toList(), [2, 3]);
    });

    test('addReplyはアカウントと投稿を1件ずつ追加し、order:2から採番する', () async {
      final arg = buildDetailArg();
      final notifier = detailContainer.read(
        postDetailEditorProvider(arg).notifier,
      );
      final initial = detailContainer.read(postDetailEditorProvider(arg));
      final initialAccountCount = initial.accounts.length;

      await notifier.addReply();

      final state = detailContainer.read(postDetailEditorProvider(arg));
      final replies = repliesOf(state);
      expect(replies.length, 1);
      expect(replies.first.order, 2);
      expect(state.accounts.length, initialAccountCount + 1);

      final saved = detailRepository.getAll(detailProject).single;
      expect(repliesOf(saved).length, 1);
    });

    test('removeReplyは対象の投稿・アカウントを削除しorderを2始まりで詰め直す', () async {
      final arg = buildDetailArg();
      final notifier = detailContainer.read(
        postDetailEditorProvider(arg).notifier,
      );
      await notifier.addReply();
      await notifier.addReply();
      await notifier.addReply();

      final before = detailContainer.read(postDetailEditorProvider(arg));
      final target = repliesOf(before)[1];

      await notifier.removeReply(target);

      final after = detailContainer.read(postDetailEditorProvider(arg));
      final replies = repliesOf(after);
      expect(replies.length, 2);
      expect(replies.map((p) => p.order).toList(), [2, 3]);
      expect(replies.any((p) => p.id == target.id), isFalse);
      expect(after.accounts.any((a) => a.id == target.accountId), isFalse);
    });

    test('reorderReplyはリプライのみを対象に並び替え、orderを2始まりで振り直す', () async {
      final arg = buildDetailArg();
      final notifier = detailContainer.read(
        postDetailEditorProvider(arg).notifier,
      );
      await notifier.addReply();
      await notifier.addReply();
      await notifier.addReply();

      final before = detailContainer.read(postDetailEditorProvider(arg));
      final firstReplyId = repliesOf(before).first.id;

      // 先頭のリプライを末尾(index 2)へ移動する
      await notifier.reorderReply(0, 2);

      final after = detailContainer.read(postDetailEditorProvider(arg));
      final replies = repliesOf(after);
      expect(replies.last.id, firstReplyId);
      expect(replies.map((p) => p.order).toList(), [2, 3, 4]);
    });

    test('引用ポストと共存してもリプライのorder採番は常に2から始まる', () async {
      final arg = buildDetailArg();
      final notifier = detailContainer.read(
        postDetailEditorProvider(arg).notifier,
      );

      await notifier.addQuotedPost();
      await notifier.addReply();

      final state = detailContainer.read(postDetailEditorProvider(arg));
      expect(quotedPostOf(state)!.order, 1);
      expect(repliesOf(state).single.order, 2);
    });
  });
}
