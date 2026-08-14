import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/project.dart';
import '../../providers/project_providers.dart';
import '../scene_list/scene_list_page.dart';

class ProjectListPage extends ConsumerWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('プロジェクト')),
      body: projects.isEmpty
          ? const _EmptyState()
          : ListView.builder(
              itemCount: projects.length,
              itemBuilder: (context, index) {
                return _ProjectListTile(project: projects[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectDialog(context, ref),
        tooltip: '新規プロジェクト',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateProjectDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final trimmedName = await _showProjectNameDialog(
      context,
      title: '新規プロジェクト',
      confirmLabel: '作成',
    );
    if (trimmedName == null) return;
    await ref.read(projectListProvider.notifier).createProject(trimmedName);
  }
}

Future<String?> _showProjectNameDialog(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String initialValue = '',
}) async {
  final controller = TextEditingController(text: initialValue);
  final name = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'プロジェクト名'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  final trimmedName = name?.trim();
  if (trimmedName == null || trimmedName.isEmpty) return null;
  return trimmedName;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'プロジェクトがありません\n右下の + から作成してください',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _ProjectListTile extends ConsumerWidget {
  const _ProjectListTile({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(project.id),
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
        ref.read(projectListProvider.notifier).deleteProject(project);
      },
      child: ListTile(
        title: Text(project.name),
        subtitle: Text('画面数: ${project.scenes.length}'),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'プロジェクト名を編集',
          onPressed: () => _showEditProjectDialog(context, ref, project),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SceneListPage(project: project),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showEditProjectDialog(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) async {
    final trimmedName = await _showProjectNameDialog(
      context,
      title: 'プロジェクト名を編集',
      confirmLabel: '保存',
      initialValue: project.name,
    );
    if (trimmedName == null || trimmedName == project.name) return;
    await ref
        .read(projectListProvider.notifier)
        .renameProject(project, trimmedName);
  }
}
