import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/account.dart';
import '../../../models/post.dart';
import '../../../models/project.dart';
import '../../../models/scene.dart';
import '../../../models/status_bar_config.dart';
import '../../../providers/editor_providers.dart';
import '../../../widgets/fake_status_bar.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/post_editor_sheet.dart';
import '../../fullscreen/fullscreen_display_page.dart';
import '../../status_bar/status_bar_config_editor_sheet.dart';

/// タイムラインエディタ画面。
///
/// 上部にFakeStatusBarを固定表示し、その下のリスト自体が投稿の
/// プレビュー・タップ編集・並び替え・削除を兼ねる(PostCardは実表示と共用)。
class TimelineEditorPage extends ConsumerWidget {
  const TimelineEditorPage({
    super.key,
    required this.project,
    required this.scene,
  });

  final Project project;
  final Scene scene;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = (project: project, scene: scene);
    final currentScene = ref.watch(timelineEditorProvider(arg));
    final notifier = ref.read(timelineEditorProvider(arg).notifier);
    final posts = List<Post>.from(currentScene.posts)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(
        title: Text(currentScene.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.smartphone_outlined),
            tooltip: 'ステータスバー設定',
            onPressed: () async {
              final updated = await showModalBottomSheet<StatusBarConfig>(
                context: context,
                isScrollControlled: true,
                builder: (_) => StatusBarConfigEditorSheet(
                  initialConfig: currentScene.statusBarConfig,
                ),
              );
              if (updated != null) await notifier.commit();
            },
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: '撮影開始',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FullscreenDisplayPage(scene: currentScene),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Material(
            elevation: 1,
            child: FakeStatusBar(config: currentScene.statusBarConfig),
          ),
          const Divider(height: 1),
          Expanded(
            child: posts.isEmpty
                ? const _EmptyState()
                : ReorderableListView.builder(
                    buildDefaultDragHandles: false,
                    itemCount: posts.length,
                    onReorderItem: notifier.reorderPost,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      final account = accountOf(currentScene, post.accountId);
                      return _TimelinePostTile(
                        key: ValueKey(post.id),
                        index: index,
                        notifier: notifier,
                        post: post,
                        account: account,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: notifier.addPost,
        tooltip: '投稿を追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '投稿がありません\n右下の + から追加してください',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _TimelinePostTile extends StatelessWidget {
  const _TimelinePostTile({
    super.key,
    required this.index,
    required this.notifier,
    required this.post,
    required this.account,
  });

  final int index;
  final TimelineEditorNotifier notifier;
  final Post post;
  final Account account;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(post.id),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.drag_handle),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => _openPostEditor(context),
                child: PostCard(post: post, account: account),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '削除',
              onPressed: () => notifier.deletePost(post),
            ),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _openPostEditor(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PostEditorSheet(
        post: post,
        account: account,
        onCommit: notifier.commit,
      ),
    );
  }
}
