import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';

/// フルスクリーン表示中のScene描画をPNGとしてキャプチャし、カメラロールへ保存する。
///
/// [screenshotController] を`Screenshot`ウィジェットに渡し、キャプチャ対象の
/// `RepaintBoundary`を紐づけて使う(`docs/.steering`の設計方針どおり、
/// エディタのプレビューと同一のWidgetツリーをそのままキャプチャする)。
class ImageExportController {
  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> exportToGallery() async {
    final bytes = await screenshotController.capture();
    if (bytes == null) {
      throw const ImageExportFailure('画像のキャプチャに失敗しました');
    }

    try {
      // putImageBytes内部でアクセス権限のリクエストも行われるため、
      // 事前のhasAccess/requestAccess呼び出しは不要。
      await Gal.putImageBytes(
        bytes,
        name: 'fake_x_post_${DateTime.now().millisecondsSinceEpoch}',
      );
    } on GalException catch (error) {
      throw ImageExportFailure(_messageFor(error.type));
    }
  }

  String _messageFor(GalExceptionType type) {
    switch (type) {
      case GalExceptionType.accessDenied:
        return 'カメラロールへのアクセスが許可されていません';
      case GalExceptionType.notEnoughSpace:
        return '端末の空き容量が不足しています';
      case GalExceptionType.notSupportedFormat:
        return '対応していない画像形式です';
      case GalExceptionType.unexpected:
        return '画像の保存に失敗しました';
    }
  }
}

/// [ImageExportController]で発生した、ユーザーへそのまま提示できるエラー。
class ImageExportFailure implements Exception {
  const ImageExportFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
