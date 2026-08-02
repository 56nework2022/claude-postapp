import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screenshot/screenshot.dart';

import 'package:fake_x_post_maker/features/fullscreen/image_export_controller.dart';

void main() {
  const channel = MethodChannel('gal');

  void mockGalChannel(
    Future<Object?> Function(MethodCall call) handler,
  ) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('キャプチャ対象が未マウントの場合はImageExportFailureを投げる', () async {
    final controller = ImageExportController();

    await expectLater(
      controller.exportToGallery(),
      throwsA(
        isA<ImageExportFailure>().having(
          (e) => e.message,
          'message',
          '画像のキャプチャに失敗しました',
        ),
      ),
    );
  });

  testWidgets('キャプチャに成功するとGal.putImageBytesが呼ばれる', (tester) async {
    final controller = ImageExportController();
    await tester.pumpWidget(
      MaterialApp(
        home: Screenshot(
          controller: controller.screenshotController,
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );

    final calledMethods = <String>[];
    mockGalChannel((call) async {
      calledMethods.add(call.method);
      switch (call.method) {
        case 'requestAccess':
          return true;
        default:
          return null;
      }
    });

    // screenshotパッケージのcapture()は実際のFuture.delayedや
    // RenderRepaintBoundary.toImage()(エンジン側との実時間でのやりとり)を
    // 使うため、testWidgets既定のFakeAsyncゾーンの外(runAsync)で実行する
    // 必要がある(Hiveの実ディスクI/Oと同様の既知の制約。tasklist.mdのタスク3参照)。
    await tester.runAsync(() => controller.exportToGallery());

    expect(calledMethods, contains('putImageBytes'));
  });

  testWidgets('Galがアクセス拒否エラーを返すと日本語メッセージのImageExportFailureになる', (
    tester,
  ) async {
    final controller = ImageExportController();
    await tester.pumpWidget(
      MaterialApp(
        home: Screenshot(
          controller: controller.screenshotController,
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    );

    mockGalChannel((call) async {
      if (call.method == 'requestAccess') return true;
      throw PlatformException(code: 'ACCESS_DENIED', message: 'denied');
    });

    Object? caughtError;
    await tester.runAsync(() async {
      try {
        await controller.exportToGallery();
      } catch (error) {
        caughtError = error;
      }
    });

    expect(caughtError, isA<ImageExportFailure>());
    expect(
      (caughtError as ImageExportFailure).message,
      'カメラロールへのアクセスが許可されていません',
    );
  });
}
