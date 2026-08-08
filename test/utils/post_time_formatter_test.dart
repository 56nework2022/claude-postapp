import 'package:flutter_test/flutter_test.dart';

import 'package:fake_post_maker/utils/post_time_formatter.dart';

void main() {
  group('formatRelativeTime', () {
    final now = DateTime(2026, 8, 2, 12, 0);

    test('1分未満は「たった今」になる', () {
      final postedAt = now.subtract(const Duration(seconds: 30));
      expect(formatRelativeTime(postedAt, now: now), 'たった今');
    });

    test('1時間未満は分単位で表示される', () {
      final postedAt = now.subtract(const Duration(minutes: 5));
      expect(formatRelativeTime(postedAt, now: now), '5分');
    });

    test('24時間未満は時間単位で表示される', () {
      final postedAt = now.subtract(const Duration(hours: 3));
      expect(formatRelativeTime(postedAt, now: now), '3時間');
    });

    test('24時間以上は日単位で表示される', () {
      final postedAt = now.subtract(const Duration(days: 2));
      expect(formatRelativeTime(postedAt, now: now), '2日');
    });
  });

  group('formatAbsoluteDateTime', () {
    test('午前・午後と日付を含む形式で表示される', () {
      expect(
        formatAbsoluteDateTime(DateTime(2026, 8, 1, 15, 0)),
        '午後3:00 · 2026年8月1日',
      );
      expect(
        formatAbsoluteDateTime(DateTime(2026, 8, 1, 0, 5)),
        '午前12:05 · 2026年8月1日',
      );
    });
  });
}
