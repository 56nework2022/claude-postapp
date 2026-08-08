import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_post_maker/features/status_bar/status_bar_config_editor_sheet.dart';
import 'package:fake_post_maker/models/status_bar_config.dart';

void main() {
  testWidgets('OS切り替え・手動時刻・充電中トグルを変更して保存すると変更が返される', (tester) async {
    final config = StatusBarConfig(
      platform: StatusBarPlatform.ios,
      timeMode: TimeMode.current,
      signalLevel: 3,
      batteryLevel: 50,
      isCharging: false,
    );
    StatusBarConfig? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await Navigator.of(context).push<StatusBarConfig>(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: StatusBarConfigEditorSheet(initialConfig: config),
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

    await tester.tap(find.text('Android風'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('手動指定'));
    await tester.pumpAndSettle();

    expect(find.text('時刻(例: 9:41)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '10:15');

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.platform, StatusBarPlatform.android);
    expect(result!.timeMode, TimeMode.manual);
    expect(result!.manualTime, '10:15');
    expect(result!.isCharging, isTrue);
    expect(result!.signalLevel, 3);
    expect(result!.batteryLevel, 50);
  });
}
