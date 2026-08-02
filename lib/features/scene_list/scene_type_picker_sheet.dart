import 'package:flutter/material.dart';

import '../../models/scene.dart';

class SceneTypePickerSheet extends StatelessWidget {
  const SceneTypePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.view_agenda_outlined),
            title: const Text('タイムライン'),
            onTap: () => Navigator.of(context).pop(SceneType.timeline),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('投稿詳細'),
            onTap: () => Navigator.of(context).pop(SceneType.postDetail),
          ),
        ],
      ),
    );
  }
}
