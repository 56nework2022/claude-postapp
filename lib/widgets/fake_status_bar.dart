import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../models/status_bar_config.dart';

/// OS実機のステータスバーの代わりにアプリが描画する疑似ステータスバー。
///
/// [StatusBarConfig.platform] に応じてiPhone風(丸ドットの電波表示)/
/// Android風(バー型の電波表示)を切り替える。OS依存の分岐はこのWidget内に
/// 閉じ込め、呼び出し側(エディタ・フルスクリーン表示)には漏らさない。
class FakeStatusBar extends StatelessWidget {
  const FakeStatusBar({super.key, required this.config});

  final StatusBarConfig config;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.statusBarBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_timeLabel(), style: AppTextStyles.statusBarTime),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (config.platform == StatusBarPlatform.ios)
                  _SignalDots(level: config.signalLevel)
                else
                  _SignalBars(level: config.signalLevel),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.wifi,
                  size: 15,
                  color: AppColors.statusBarForeground,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('${config.batteryLevel}%', style: AppTextStyles.statusBarLabel),
                const SizedBox(width: AppSpacing.xs),
                _BatteryIndicator(
                  level: config.batteryLevel,
                  charging: config.isCharging,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel() {
    if (config.timeMode == TimeMode.manual) {
      return config.manualTime ?? '';
    }
    final now = DateTime.now();
    final minute = now.minute.toString().padLeft(2, '0');
    return '${now.hour}:$minute';
  }
}

/// iPhone風の電波表示(4つの丸ドット)。
class _SignalDots extends StatelessWidget {
  const _SignalDots({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final isActive = index < level;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? AppColors.statusBarForeground
                  : AppColors.statusBarInactive,
            ),
          ),
        );
      }),
    );
  }
}

/// Android風の電波表示(高さの異なる4本のバー)。
class _SignalBars extends StatelessWidget {
  const _SignalBars({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    const heights = [5.0, 8.0, 11.0, 14.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        final isActive = index < level;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Container(
            width: 3,
            height: heights[index],
            color: isActive
                ? AppColors.statusBarForeground
                : AppColors.statusBarInactive,
          ),
        );
      }),
    );
  }
}

/// iPhone/Android共通の電池アイコン(輪郭+充填率+充電中バッジ)。
class _BatteryIndicator extends StatelessWidget {
  const _BatteryIndicator({required this.level, required this.charging});

  final int level;
  final bool charging;

  @override
  Widget build(BuildContext context) {
    final fillRatio = (level.clamp(0, 100)) / 100;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 11,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: AppColors.statusBarForeground, width: 1.2),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: fillRatio,
                heightFactor: 1.0,
                child: const ColoredBox(color: AppColors.statusBarForeground),
              ),
              if (charging)
                const Center(
                  child: Icon(
                    Icons.bolt,
                    size: 8,
                    color: AppColors.statusBarBackground,
                  ),
                ),
            ],
          ),
        ),
        Container(
          width: 2,
          height: 4,
          margin: const EdgeInsets.only(left: 1),
          decoration: const BoxDecoration(
            color: AppColors.statusBarForeground,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(1)),
          ),
        ),
      ],
    );
  }
}
