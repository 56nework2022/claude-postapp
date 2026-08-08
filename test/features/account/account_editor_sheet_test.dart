import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_post_maker/features/account/account_editor_sheet.dart';
import 'package:fake_post_maker/models/account.dart';

void main() {
  testWidgets('表示名・ユーザー名・認証バッジを編集して保存すると変更が返される', (tester) async {
    final account = Account(
      id: 'a1',
      displayName: '元の名前',
      username: 'old_user',
    );
    Account? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<Account>(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: AccountEditorSheet(initialAccount: account),
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), '新しい名前');
    await tester.enterText(textFields.at(1), 'new_user');
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.displayName, '新しい名前');
    expect(result!.username, 'new_user');
    expect(result!.isVerified, isTrue);
  });

  testWidgets('アイコン未設定時はプレースホルダーアイコンが表示される', (tester) async {
    final account = Account(id: 'a1', displayName: '名前', username: 'user');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AccountEditorSheet(initialAccount: account)),
      ),
    );

    expect(find.byIcon(Icons.person), findsOneWidget);
  });
}
