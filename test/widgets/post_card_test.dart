import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_x_post_maker/models/account.dart';
import 'package:fake_x_post_maker/models/post.dart';
import 'package:fake_x_post_maker/widgets/post_card.dart';

/// `transparent_image`パッケージ等で広く使われる、有効な1x1透明PNGのバイト列。
/// デコードが(テスト内で待たなくても)裏で成功して静かに終わるようにするため、
/// 壊れたバイト列ではなくこちらを使う。
const _transparentPngBytes = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
  0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62,
  0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4,
  0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60,
  0x82,
];

void main() {
  final account = Account(
    id: 'a1',
    displayName: '表示名',
    username: 'username',
    isVerified: true,
  );
  final post = Post(
    id: 'p1',
    accountId: 'a1',
    body: '本文テスト',
    likeCountLabel: '1.2万',
    repostCountLabel: '3.4万',
    replyCountLabel: '12',
    postedAt: DateTime(2026, 8, 1, 15, 0),
    order: 0,
  );

  testWidgets('timelineバリアントでは相対時刻とアカウント情報が表示される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PostCard(post: post, account: account)),
      ),
    );

    expect(find.text('本文テスト'), findsOneWidget);
    expect(find.textContaining('@username'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3.4万'), findsOneWidget);
    expect(find.text('1.2万'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('detailバリアントでは絶対日時が表示される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(
            post: post,
            account: account,
            variant: PostCardVariant.detail,
          ),
        ),
      ),
    );

    expect(find.text('午後3:00 · 2026年8月1日'), findsOneWidget);
  });

  testWidgets('quotedChildを渡すと入れ子表示される', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(
            post: post,
            account: account,
            variant: PostCardVariant.detail,
            quotedChild: PostCard(post: post, account: account),
          ),
        ),
      ),
    );

    expect(find.byType(PostCard), findsNWidgets(2));
  });

  testWidgets('imagePathがある投稿は画像が表示され、ない投稿は表示されない', (tester) async {
    // 実ファイルI/O(一時ディレクトリ作成・書き込み・削除)はFakeAsyncゾーン内で
    // awaitすると永久にハングするため`tester.runAsync`で実時間実行する
    // (`.steering/20260801-initial-implementation/tasklist.md`記載の既知の制約と同様)。
    // 画像デコード完了自体は待たず、Widgetツリーに`Image`が組み込まれるかどうか
    // (=`Post.imagePath`の有無で表示が切り替わるか)だけを検証する。
    late Directory tempDir;
    late File imageFile;
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('post_card_test_');
      imageFile = File('${tempDir.path}/attached.png');
      await imageFile.writeAsBytes(_transparentPngBytes);
    });

    final postWithImage = Post(
      id: 'p2',
      accountId: 'a1',
      body: '画像付き投稿',
      likeCountLabel: '1',
      repostCountLabel: '2',
      replyCountLabel: '3',
      postedAt: DateTime(2026, 8, 1, 15, 0),
      order: 0,
      imagePath: imageFile.path,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PostCard(post: postWithImage, account: account)),
      ),
    );
    expect(find.byType(Image), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PostCard(post: post, account: account)),
      ),
    );
    expect(find.byType(Image), findsNothing);

    await tester.runAsync(() async {
      await tempDir.delete(recursive: true);
    });
  });
}
