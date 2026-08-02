import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fake_x_post_maker/models/status_bar_config.dart';
import 'package:fake_x_post_maker/widgets/fake_status_bar.dart';

void main() {
  Future<void> pumpFakeStatusBar(
    WidgetTester tester,
    StatusBarConfig config,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: FakeStatusBar(config: config))),
    );
  }

  testWidgets('手動時刻モードでは指定した時刻がそのまま表示される', (tester) async {
    await pumpFakeStatusBar(
      tester,
      StatusBarConfig(
        platform: StatusBarPlatform.ios,
        timeMode: TimeMode.manual,
        manualTime: '9:41',
        signalLevel: 4,
        batteryLevel: 78,
        isCharging: false,
      ),
    );

    expect(find.text('9:41'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
  });

  testWidgets('Android風でも例外なく描画できる', (tester) async {
    await pumpFakeStatusBar(
      tester,
      StatusBarConfig(
        platform: StatusBarPlatform.android,
        timeMode: TimeMode.manual,
        manualTime: '13:05',
        signalLevel: 2,
        batteryLevel: 42,
        isCharging: true,
      ),
    );

    expect(find.text('13:05'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });
}
