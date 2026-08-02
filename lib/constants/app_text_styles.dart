import 'package:flutter/material.dart';

/// アプリ全体で使い回すタイポグラフィトークン。
///
/// 画面本文のスタイルは `ThemeData.textTheme` に集約し、
/// ここでは`ThemeData`では表現しづらいOS依存の疑似UI(ステータスバー等)
/// 専用のスタイルのみを定義する。
class AppTextStyles {
  const AppTextStyles._();

  static const statusBarTime = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static const statusBarLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );
}
