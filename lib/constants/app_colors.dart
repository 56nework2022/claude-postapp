import 'package:flutter/material.dart';

/// アプリ全体で使い回す配色トークン。
class AppColors {
  const AppColors._();

  /// 疑似ステータスバー(FakeStatusBar)の背景色。
  static const statusBarBackground = Colors.white;

  /// 疑似ステータスバーの文字・アイコン色。
  static const statusBarForeground = Colors.black;

  /// 疑似ステータスバーの非アクティブなアイコン(電波の未点灯バー等)の色。
  static const statusBarInactive = Color(0xFFBDBDBD);

  /// 認証バッジの色(Xの公式カラーではなく汎用的な青)。
  static const verifiedBadge = Color(0xFF2196F3);
}
