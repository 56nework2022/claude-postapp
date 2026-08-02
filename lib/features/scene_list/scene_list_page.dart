import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/project.dart';
import '../../models/scene.dart';
import '../../providers/scene_providers.dart';
import '../editors/post_detail/post_detail_editor_page.dart';
import '../editors/timeline/timeline_editor_page.dart';
import 'scene_type_picker_sheet.dart';

String sceneTypeLabel(SceneType type) {
  switch (type) {
    case SceneType.timeline:
      return 'タイムライン';
    case SceneType.postDetail:
      return '投稿詳細';
    case SceneType.profile:
      return 'プロフィール';
    case SceneType.dm:
      return 'DM';
  }
}

Future<void> _openEditor(
  BuildContext context,
  Project project,
  Scene scene,
) async {
  switch (scene.type) {
    case SceneType.postDetail:
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailEditorPage(project: project, scene: scene),
        ),
      );
    case SceneType.timeline:
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TimelineEditorPage(project: project, scene: scene),
        ),
      );
    case SceneType.profile:
    case SceneType.dm:
      // プロフィール・DMのエディタは未実装(フェーズ2・3で対応)
      break;
  }
}

IconData _sceneTypeIcon(SceneType type) {
  switch (type) {
    case SceneType.timeline:
      return Icons.view_agenda_outlined;
    case SceneType.postDetail:
      return Icons.article_outlined;
    case SceneType.profile:
      return Icons.person_outline;
    case SceneType.dm:
      return Icons.mail_outline;
  }
}

class SceneListPage extends ConsumerWidget {
  const SceneListPage({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(sceneListProvider(project));

    return Scaffold(
      appBar: AppBar(title: Text(project.name)),
      body: scenes.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              itemCount: scenes.length,
              itemBuilder: (context, index) {
                return _SceneListTile(project: project, scene: scenes[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTypePicker(context, ref),
        tooltip: '新規画面',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openTypePicker(BuildContext context, WidgetRef ref) async {
    final type = await showModalBottomSheet<SceneType>(
      context: context,
      builder: (_) => const SceneTypePickerSheet(),
    );
    if (type == null) return;

    final createdScene = await ref
        .read(sceneListProvider(project).notifier)
        .createScene(title: sceneTypeLabel(type), type: type);

    if (!context.mounted) return;
    await _openEditor(context, project, createdScene);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '画面がありません\n右下の + から作成してください',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _SceneListTile extends ConsumerWidget {
  const _SceneListTile({required this.project, required this.scene});

  final Project project;
  final Scene scene;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(scene.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(
          Icons.delete,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) {
        ref.read(sceneListProvider(project).notifier).deleteScene(scene);
      },
      child: ListTile(
        leading: Icon(_sceneTypeIcon(scene.type)),
        title: Text(scene.title),
        subtitle: Text(sceneTypeLabel(scene.type)),
        onTap: () => _openEditor(context, project, scene),
      ),
    );
  }
}
