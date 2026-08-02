/// タイムライン用の相対時刻表示(例:「3時間」)を返す。
String formatRelativeTime(DateTime postedAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(postedAt);

  if (diff.inSeconds < 60) return 'たった今';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分';
  if (diff.inHours < 24) return '${diff.inHours}時間';
  return '${diff.inDays}日';
}

/// 投稿詳細用の絶対日時表示(例:「午後3:00 · 2026年8月1日」)を返す。
String formatAbsoluteDateTime(DateTime postedAt) {
  final period = postedAt.hour < 12 ? '午前' : '午後';
  final hour12 = postedAt.hour % 12 == 0 ? 12 : postedAt.hour % 12;
  final minute = postedAt.minute.toString().padLeft(2, '0');
  return '$period$hour12:$minute · ${postedAt.year}年${postedAt.month}月${postedAt.day}日';
}
