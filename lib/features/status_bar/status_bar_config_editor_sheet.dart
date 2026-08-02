import 'package:flutter/material.dart';

import '../../constants/app_spacing.dart';
import '../../models/status_bar_config.dart';

/// 疑似ステータスバーの設定(OS種別・時刻・電波・電池)を編集するボトムシート。
///
/// [initialConfig] を直接書き換えて保存し、`Navigator.pop` で呼び出し元へ
/// 返す。呼び出し元(投稿詳細/タイムラインエディタ)への組み込みはタスク6・7で行う。
class StatusBarConfigEditorSheet extends StatefulWidget {
  const StatusBarConfigEditorSheet({super.key, required this.initialConfig});

  final StatusBarConfig initialConfig;

  @override
  State<StatusBarConfigEditorSheet> createState() =>
      _StatusBarConfigEditorSheetState();
}

class _StatusBarConfigEditorSheetState
    extends State<StatusBarConfigEditorSheet> {
  late StatusBarPlatform _platform;
  late TimeMode _timeMode;
  late final TextEditingController _manualTimeController;
  late int _signalLevel;
  late int _batteryLevel;
  late bool _isCharging;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    _platform = config.platform;
    _timeMode = config.timeMode;
    _manualTimeController = TextEditingController(
      text: config.manualTime ?? '9:41',
    );
    _signalLevel = config.signalLevel;
    _batteryLevel = config.batteryLevel;
    _isCharging = config.isCharging;
  }

  @override
  void dispose() {
    _manualTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ステータスバー設定',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<StatusBarPlatform>(
              segments: const [
                ButtonSegment(
                  value: StatusBarPlatform.ios,
                  label: Text('iPhone風'),
                ),
                ButtonSegment(
                  value: StatusBarPlatform.android,
                  label: Text('Android風'),
                ),
              ],
              selected: {_platform},
              onSelectionChanged: (selection) =>
                  setState(() => _platform = selection.first),
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<TimeMode>(
              segments: const [
                ButtonSegment(value: TimeMode.current, label: Text('現在時刻')),
                ButtonSegment(value: TimeMode.manual, label: Text('手動指定')),
              ],
              selected: {_timeMode},
              onSelectionChanged: (selection) =>
                  setState(() => _timeMode = selection.first),
            ),
            if (_timeMode == TimeMode.manual) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _manualTimeController,
                decoration: const InputDecoration(labelText: '時刻(例: 9:41)'),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text('電波: $_signalLevel'),
            Slider(
              value: _signalLevel.toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              label: '$_signalLevel',
              onChanged: (value) =>
                  setState(() => _signalLevel = value.round()),
            ),
            Text('電池: $_batteryLevel%'),
            Slider(
              value: _batteryLevel.toDouble(),
              min: 0,
              max: 100,
              divisions: 100,
              label: '$_batteryLevel%',
              onChanged: (value) =>
                  setState(() => _batteryLevel = value.round()),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('充電中'),
              value: _isCharging,
              onChanged: (value) => setState(() => _isCharging = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: _save, child: const Text('保存')),
          ],
        ),
      ),
    );
  }

  void _save() {
    final config = widget.initialConfig
      ..platform = _platform
      ..timeMode = _timeMode
      ..manualTime = _timeMode == TimeMode.manual
          ? _manualTimeController.text.trim()
          : null
      ..signalLevel = _signalLevel
      ..batteryLevel = _batteryLevel
      ..isCharging = _isCharging;
    Navigator.of(context).pop(config);
  }
}
