import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_x_post_maker/features/fullscreen/fullscreen_display_page.dart';
import 'package:fake_x_post_maker/models/account.dart';
import 'package:fake_x_post_maker/models/post.dart';
import 'package:fake_x_post_maker/models/scene.dart';
import 'package:fake_x_post_maker/models/status_bar_config.dart';
import 'package:fake_x_post_maker/widgets/post_card.dart';

void main() {
  Scene buildScene({
    required SceneType type,
    List<Post> posts = const [],
    List<Account> accounts = const [],
  }) {
    return Scene(
      id: 'scene-1',
      projectId: 'project-1',
      type: type,
      title: 'テスト画面',
      order: 0,
      statusBarConfig: StatusBarConfig(
        platform: StatusBarPlatform.ios,
        timeMode: TimeMode.manual,
        manualTime: '9:41',
        signalLevel: 4,
        batteryLevel: 100,
        isCharging: false,
      ),
      accounts: accounts,
      posts: posts,
      createdAt: DateTime(2026, 8, 1),
      updatedAt: DateTime(2026, 8, 1),
    );
  }

  Post buildPost({
    required String id,
    required int order,
    String body = '本文',
  }) {
    return Post(
      id: id,
      accountId: 'account-1',
      body: body,
      likeCountLabel: '0',
      repostCountLabel: '0',
      replyCountLabel: '0',
      postedAt: DateTime(2026, 8, 1, 15, 0),
      order: order,
    );
  }

  final account = Account(
    id: 'account-1',
    displayName: '表示名',
    username: 'username',
  );

  testWidgets('投稿詳細Sceneではメイン投稿とステータスバーが表示される', (tester) async {
    final scene = buildScene(
      type: SceneType.postDetail,
      posts: [buildPost(id: 'post-1', order: 0)],
      accounts: [account],
    );

    await tester.pumpWidget(MaterialApp(home: FullscreenDisplayPage(scene: scene)));

    expect(find.text('9:41'), findsOneWidget);
    expect(find.byType(PostCard), findsOneWidget);
    expect(find.text('本文'), findsOneWidget);
  });

  testWidgets('タイムラインSceneではorder順に複数投稿が一覧表示される', (tester) async {
    final scene = buildScene(
      type: SceneType.timeline,
      posts: [
        buildPost(id: 'post-2', order: 1, body: '投稿2'),
        buildPost(id: 'post-1', order: 0, body: '投稿1'),
      ],
      accounts: [account],
    );

    await tester.pumpWidget(MaterialApp(home: FullscreenDisplayPage(scene: scene)));

    expect(find.byType(PostCard), findsNWidgets(2));
    final bodies = tester
        .widgetList<PostCard>(find.byType(PostCard))
        .map((card) => card.post.body)
        .toList();
    expect(bodies, ['投稿1', '投稿2']);
  });

  testWidgets('投稿が1件もないタイムラインでは空の状態メッセージが表示される', (tester) async {
    final scene = buildScene(type: SceneType.timeline, accounts: [account]);

    await tester.pumpWidget(MaterialApp(home: FullscreenDisplayPage(scene: scene)));

    expect(find.text('投稿がありません'), findsOneWidget);
  });

  testWidgets('画面をタップすると戻るボタンがトグル表示される', (tester) async {
    final scene = buildScene(
      type: SceneType.postDetail,
      posts: [buildPost(id: 'post-1', order: 0)],
      accounts: [account],
    );

    await tester.pumpWidget(MaterialApp(home: FullscreenDisplayPage(scene: scene)));

    expect(find.byIcon(Icons.arrow_back), findsNothing);

    final toggleFinder = find.byKey(const ValueKey('fullscreen-toggle-controls'));

    await tester.tap(toggleFinder);
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(toggleFinder);
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });
}
