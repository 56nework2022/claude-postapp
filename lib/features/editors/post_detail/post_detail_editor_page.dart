import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_spacing.dart';
import '../../../models/account.dart';
import '../../../models/post.dart';
import '../../../models/project.dart';
import '../../../models/scene.dart';
import '../../../models/status_bar_config.dart';
import '../../../providers/editor_providers.dart';
import '../../../widgets/fake_status_bar.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/post_editor_sheet.dart';
import '../../../widgets/post_fields_form.dart';
import '../../account/account_editor_sheet.dart';
import '../../fullscreen/fullscreen_display_page.dart';
import '../../status_bar/status_bar_config_editor_sheet.dart';

/// 投稿詳細エディタ画面。
///
/// 上部にFakeStatusBar+PostCardによるリアルタイムプレビューを表示し、
/// 下部のフォームで本文・数値ラベル・日時・アカウント・ステータスバー・
/// 引用ポストを編集する。
class PostDetailEditorPage extends ConsumerWidget {
  const PostDetailEditorPage({
    super.key,
    required this.project,
    required this.scene,
  });

  final Project project;
  final Scene scene;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arg = (project: project, scene: scene);
    final currentScene = ref.watch(postDetailEditorProvider(arg));
    final notifier = ref.read(postDetailEditorProvider(arg).notifier);

    final mainPost = mainPostOf(currentScene);
    final mainAccount = accountOf(currentScene, mainPost.accountId);
    final quotedPost = quotedPostOf(currentScene);
    final quotedAccount = quotedPost == null
        ? null
        : accountOf(currentScene, quotedPost.accountId);
    final replies = repliesOf(currentScene);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentScene.title),
        actions: [
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
            child: Column(
              children: [
                FakeStatusBar(config: currentScene.statusBarConfig),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.4,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        PostCard(
                          post: mainPost,
                          account: mainAccount,
                          variant: PostCardVariant.detail,
                          quotedChild:
                              quotedPost == null || quotedAccount == null
                              ? null
                              : PostCard(
                                  post: quotedPost,
                                  account: quotedAccount,
                                ),
                        ),
                        for (final reply in replies)
                          PostCard(
                            key: ValueKey('reply-preview-${reply.id}'),
                            post: reply,
                            account: accountOf(currentScene, reply.accountId),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _AccountAndStatusBarSection(
                  notifier: notifier,
                  scene: currentScene,
                  mainAccount: mainAccount,
                ),
                const Divider(height: AppSpacing.xl),
                PostFieldsForm(
                  key: ValueKey('main-${mainPost.id}'),
                  post: mainPost,
                  onChanged: notifier.commit,
                ),
                const Divider(height: AppSpacing.xl),
                _QuotedPostSection(
                  notifier: notifier,
                  quotedPost: quotedPost,
                  quotedAccount: quotedAccount,
                ),
                const Divider(height: AppSpacing.xl),
                _RepliesSection(
                  notifier: notifier,
                  scene: currentScene,
                  replies: replies,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountAndStatusBarSection extends StatelessWidget {
  const _AccountAndStatusBarSection({
    required this.notifier,
    required this.scene,
    required this.mainAccount,
  });

  final PostDetailEditorNotifier notifier;
  final Scene scene;
  final Account mainAccount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle_outlined),
          title: const Text('アカウント設定'),
          subtitle: Text('${mainAccount.displayName} (@${mainAccount.username})'),
          onTap: () async {
            final updated = await showModalBottomSheet<Account>(
              context: context,
              isScrollControlled: true,
              builder: (_) => AccountEditorSheet(initialAccount: mainAccount),
            );
            if (updated != null) await notifier.commit();
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.smartphone_outlined),
          title: const Text('ステータスバー設定'),
          onTap: () async {
            final updated = await showModalBottomSheet<StatusBarConfig>(
              context: context,
              isScrollControlled: true,
              builder: (_) =>
                  StatusBarConfigEditorSheet(initialConfig: scene.statusBarConfig),
            );
            if (updated != null) await notifier.commit();
          },
        ),
      ],
    );
  }
}

class _QuotedPostSection extends StatelessWidget {
  const _QuotedPostSection({
    required this.notifier,
    required this.quotedPost,
    required this.quotedAccount,
  });

  final PostDetailEditorNotifier notifier;
  final Post? quotedPost;
  final Account? quotedAccount;

  @override
  Widget build(BuildContext context) {
    final quoted = quotedPost;
    final account = quotedAccount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('引用ポストを追加'),
          value: quoted != null,
          onChanged: (value) =>
              value ? notifier.addQuotedPost() : notifier.removeQuotedPost(),
        ),
        if (quoted != null && account != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('引用元アカウント設定'),
            subtitle: Text('${account.displayName} (@${account.username})'),
            onTap: () async {
              final updated = await showModalBottomSheet<Account>(
                context: context,
                isScrollControlled: true,
                builder: (_) => AccountEditorSheet(initialAccount: account),
              );
              if (updated != null) await notifier.commit();
            },
          ),
          PostFieldsForm(
            key: ValueKey('quoted-${quoted.id}'),
            post: quoted,
            title: '引用ポストの内容',
            onChanged: notifier.commit,
          ),
        ],
      ],
    );
  }
}

class _RepliesSection extends StatelessWidget {
  const _RepliesSection({
    required this.notifier,
    required this.scene,
    required this.replies,
  });

  final PostDetailEditorNotifier notifier;
  final Scene scene;
  final List<Post> replies;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'リプライ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: notifier.addReply,
              icon: const Icon(Icons.add),
              label: const Text('リプライを追加'),
            ),
          ],
        ),
        if (replies.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: replies.length,
            onReorderItem: notifier.reorderReply,
            itemBuilder: (context, index) {
              final reply = replies[index];
              final account = accountOf(scene, reply.accountId);
              return _ReplyTile(
                key: ValueKey(reply.id),
                index: index,
                notifier: notifier,
                post: reply,
                account: account,
              );
            },
          ),
      ],
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({
    super.key,
    required this.index,
    required this.notifier,
    required this.post,
    required this.account,
  });

  final int index;
  final PostDetailEditorNotifier notifier;
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
                onTap: () => _openReplyEditor(context),
                child: PostCard(post: post, account: account),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '削除',
              onPressed: () => notifier.removeReply(post),
            ),
          ],
        ),
        const Divider(height: 1),
      ],
    );
  }

  Future<void> _openReplyEditor(BuildContext context) async {
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
