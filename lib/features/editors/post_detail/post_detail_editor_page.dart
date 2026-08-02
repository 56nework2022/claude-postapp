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
                PostCard(
                  post: mainPost,
                  account: mainAccount,
                  variant: PostCardVariant.detail,
                  quotedChild: quotedPost == null || quotedAccount == null
                      ? null
                      : PostCard(post: quotedPost, account: quotedAccount),
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
