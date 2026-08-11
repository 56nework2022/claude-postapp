import 'package:flutter/material.dart';

import '../../data/hive_boxes.dart';

const String _disclaimerAcknowledgedKey = 'disclaimer_acknowledged';

/// アプリ初回起動時に一度だけ、フィクション作成ツールである旨のダイアログを表示する。
class DisclaimerGate extends StatefulWidget {
  const DisclaimerGate({required this.child, super.key});

  final Widget child;

  @override
  State<DisclaimerGate> createState() => _DisclaimerGateState();
}

class _DisclaimerGateState extends State<DisclaimerGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showIfNeeded());
  }

  Future<void> _showIfNeeded() async {
    final acknowledged =
        HiveBoxes.appSettingsBox.get(_disclaimerAcknowledgedKey) as bool? ??
        false;
    if (acknowledged || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ご利用にあたって'),
          content: const Text(
            '本アプリは映像・演劇制作用のフィクション作成ツールです。\n'
            '実在の人物・団体になりすます目的や、誤情報の拡散を目的とした使用はできません。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('同意する'),
            ),
          ],
        );
      },
    );

    await HiveBoxes.appSettingsBox.put(_disclaimerAcknowledgedKey, true);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
