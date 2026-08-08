import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/account.dart';
import '../models/post.dart';
import '../models/project.dart';
import '../models/scene.dart';
import 'scene_providers.dart';

/// 各種エディタが編集対象とする(Project, Scene)の組。
typedef SceneEditorArg = ({Project project, Scene scene});

/// メイン投稿(order:0)を返す。投稿詳細Sceneには常に1件存在する前提。
Post mainPostOf(Scene scene) =>
    scene.posts.firstWhere((post) => post.order == 0);

/// 引用ポスト(order:1)があれば返す。なければnull。
Post? quotedPostOf(Scene scene) {
  for (final post in scene.posts) {
    if (post.order == 1) return post;
  }
  return null;
}

/// リプライ投稿(order:2以上)を`order`昇順で返す。
List<Post> repliesOf(Scene scene) {
  final replies = scene.posts.where((post) => post.order >= 2).toList()
    ..sort((a, b) => a.order.compareTo(b.order));
  return replies;
}

/// 指定したaccountIdに対応するAccountを返す。
Account accountOf(Scene scene, String accountId) =>
    scene.accounts.firstWhere((account) => account.id == accountId);

String _generateId() {
  final randomSuffix = Random().nextInt(1 << 32).toRadixString(16);
  return '${DateTime.now().microsecondsSinceEpoch}-$randomSuffix';
}

Account _createDefaultAccount() {
  return Account(id: _generateId(), displayName: '表示名', username: 'username');
}

Post _createDefaultPost({required int order, required String accountId}) {
  return Post(
    id: _generateId(),
    accountId: accountId,
    body: '',
    likeCountLabel: '0',
    repostCountLabel: '0',
    replyCountLabel: '0',
    postedAt: DateTime.now(),
    order: order,
  );
}

/// [scene] を新しいインスタンスとして包み直す。
///
/// SceneはHiveObjectを持たないプレーンなクラスで`==`が未定義(参照同一性)
/// のため、フィールドを直接ミューテートしただけでは`state = state`が
/// Riverpodの変更なし判定に引っかかり再描画されない。中身(配下のリスト等)は
/// 使い回したまま識別子だけ変えることで、購読側に変更を伝える。
Scene _touchScene(Scene scene) {
  return Scene(
    id: scene.id,
    projectId: scene.projectId,
    type: scene.type,
    title: scene.title,
    order: scene.order,
    statusBarConfig: scene.statusBarConfig,
    accounts: scene.accounts,
    posts: scene.posts,
    createdAt: scene.createdAt,
    updatedAt: scene.updatedAt,
  );
}

// ---------------------------------------------------------------------------
// 投稿詳細エディタ
// ---------------------------------------------------------------------------

final postDetailEditorProvider = NotifierProvider.family<
  PostDetailEditorNotifier,
  Scene,
  SceneEditorArg
>(PostDetailEditorNotifier.new);

/// 投稿詳細エディタの状態管理。
///
/// [state] のScene・その配下のAccount/Postは直接ミューテートする方針とし、
/// 編集操作のたびに[commit]を呼んでHiveへの保存とプレビューの再描画を行う。
class PostDetailEditorNotifier extends FamilyNotifier<Scene, SceneEditorArg> {
  @override
  Scene build(SceneEditorArg arg) {
    final scene = arg.scene;
    if (!scene.posts.any((post) => post.order == 0)) {
      if (scene.accounts.isEmpty) {
        scene.accounts.add(_createDefaultAccount());
      }
      scene.posts.add(
        _createDefaultPost(order: 0, accountId: scene.accounts.first.id),
      );
    }
    return scene;
  }

  /// メイン投稿・アカウント・ステータスバー設定へのフィールド変更を
  /// 直接ミューテートした後に呼び出す。Hiveへ保存し、プレビューの再描画を促す。
  Future<void> commit() async {
    await ref.read(sceneRepositoryProvider).update(arg.project, state);
    state = _touchScene(state);
  }

  Future<void> addQuotedPost() async {
    if (quotedPostOf(state) != null) return;
    final account = _createDefaultAccount();
    state.accounts.add(account);
    final quoted = _createDefaultPost(order: 1, accountId: account.id);
    state.posts.add(quoted);
    mainPostOf(state).quotedPostId = quoted.id;
    await commit();
  }

  Future<void> removeQuotedPost() async {
    final quoted = quotedPostOf(state);
    if (quoted == null) return;
    state.posts.removeWhere((post) => post.id == quoted.id);
    state.accounts.removeWhere((account) => account.id == quoted.accountId);
    mainPostOf(state).quotedPostId = null;
    await commit();
  }

  Future<void> addReply() async {
    final account = _createDefaultAccount();
    state.accounts.add(account);
    final reply = _createDefaultPost(
      order: 2 + repliesOf(state).length,
      accountId: account.id,
    );
    state.posts.add(reply);
    await commit();
  }

  Future<void> removeReply(Post reply) async {
    state.posts.removeWhere((post) => post.id == reply.id);
    state.accounts.removeWhere((account) => account.id == reply.accountId);
    _reindexReplyOrder();
    await commit();
  }

  /// [newIndex] は`onReorderItem`が渡す値で、oldIndexの項目を取り除いた後の
  /// 挿入先を指す(取り除きによる補正は呼び出し元(Flutter側)で完了している)。
  Future<void> reorderReply(int oldIndex, int newIndex) async {
    final replies = repliesOf(state);
    final moved = replies.removeAt(oldIndex);
    replies.insert(newIndex, moved);
    for (var i = 0; i < replies.length; i++) {
      replies[i].order = 2 + i;
    }
    await commit();
  }

  void _reindexReplyOrder() {
    final replies = repliesOf(state);
    for (var i = 0; i < replies.length; i++) {
      replies[i].order = 2 + i;
    }
  }
}

// ---------------------------------------------------------------------------
// タイムラインエディタ
// ---------------------------------------------------------------------------

final timelineEditorProvider = NotifierProvider.family<
  TimelineEditorNotifier,
  Scene,
  SceneEditorArg
>(TimelineEditorNotifier.new);

/// タイムラインエディタの状態管理。
///
/// 投稿の追加・削除のたびに[order]フィールドを0始まりの連番へ振り直し、
/// 一覧の並び順とデータの整合性を保つ。
class TimelineEditorNotifier extends FamilyNotifier<Scene, SceneEditorArg> {
  @override
  Scene build(SceneEditorArg arg) => arg.scene;

  /// 投稿・アカウントへのフィールド変更を直接ミューテートした後に呼び出す。
  /// Hiveへ保存し、プレビュー・一覧の再描画を促す。
  Future<void> commit() async {
    await ref.read(sceneRepositoryProvider).update(arg.project, state);
    state = _touchScene(state);
  }

  Future<void> addPost() async {
    final account = _createDefaultAccount();
    state.accounts.add(account);
    final post = _createDefaultPost(
      order: state.posts.length,
      accountId: account.id,
    );
    state.posts.add(post);
    await commit();
  }

  Future<void> deletePost(Post post) async {
    state.posts.removeWhere((p) => p.id == post.id);
    state.accounts.removeWhere((account) => account.id == post.accountId);
    _reindexOrder();
    await commit();
  }

  /// [newIndex] は`onReorderItem`が渡す値で、oldIndexの項目を取り除いた後の
  /// 挿入先を指す(取り除きによる補正は呼び出し元(Flutter側)で完了している)。
  Future<void> reorderPost(int oldIndex, int newIndex) async {
    final posts = List<Post>.from(state.posts)
      ..sort((a, b) => a.order.compareTo(b.order));
    final moved = posts.removeAt(oldIndex);
    posts.insert(newIndex, moved);
    for (var i = 0; i < posts.length; i++) {
      posts[i].order = i;
    }
    await commit();
  }

  void _reindexOrder() {
    final posts = List<Post>.from(state.posts)
      ..sort((a, b) => a.order.compareTo(b.order));
    for (var i = 0; i < posts.length; i++) {
      posts[i].order = i;
    }
  }
}
