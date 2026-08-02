import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_x_post_maker/models/account.dart';
import 'package:fake_x_post_maker/models/post.dart';
import 'package:fake_x_post_maker/widgets/post_card.dart';

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
}
