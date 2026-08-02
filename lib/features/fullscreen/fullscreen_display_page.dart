import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../models/post.dart';
import '../../models/scene.dart';
import '../../providers/editor_providers.dart';
import '../../widgets/fake_status_bar.dart';
import '../../widgets/post_card.dart';
import 'image_export_controller.dart';

/// 撮影用フルスクリーン表示モード。
///
/// OSの通知・ステータスバー・ホームバーを`immersiveSticky`で隠し、
/// エディタと同じ`FakeStatusBar`/`PostCard`をそのまま全画面表示する。
/// タイムライン・投稿詳細どちらのSceneでもこの画面から表示できる。
class FullscreenDisplayPage extends StatefulWidget {
  const FullscreenDisplayPage({super.key, required this.scene});

  final Scene scene;

  @override
  State<FullscreenDisplayPage> createState() => _FullscreenDisplayPageState();
}

class _FullscreenDisplayPageState extends State<FullscreenDisplayPage> {
  final ImageExportController _exportController = ImageExportController();
  bool _showControls = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.statusBarBackground,
      body: GestureDetector(
        key: const ValueKey('fullscreen-toggle-controls'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            Positioned.fill(
              child: Screenshot(
                controller: _exportController.screenshotController,
                child: _SceneContent(scene: widget.scene),
              ),
            ),
            if (_showControls) ...[
              Positioned(
                top: AppSpacing.md,
                left: AppSpacing.md,
                child: SafeArea(
                  bottom: false,
                  child: FloatingActionButton.small(
                    heroTag: 'fullscreen-exit',
                    tooltip: '編集画面に戻る',
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: SafeArea(
                  bottom: false,
                  child: FloatingActionButton.small(
                    heroTag: 'fullscreen-export',
                    tooltip: '画像として書き出す',
                    onPressed: _isExporting ? null : _exportImage,
                    child: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exportImage() async {
    setState(() => _isExporting = true);
    try {
      await _exportController.exportToGallery();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カメラロールに保存しました')),
      );
    } on ImageExportFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

class _SceneContent extends StatelessWidget {
  const _SceneContent({required this.scene});

  final Scene scene;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FakeStatusBar(config: scene.statusBarConfig),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    switch (scene.type) {
      case SceneType.postDetail:
        return _PostDetailContent(scene: scene);
      case SceneType.timeline:
        return _TimelineContent(scene: scene);
      case SceneType.profile:
      case SceneType.dm:
        // フェーズ2・3で対応
        return const SizedBox.shrink();
    }
  }
}

class _PostDetailContent extends StatelessWidget {
  const _PostDetailContent({required this.scene});

  final Scene scene;

  @override
  Widget build(BuildContext context) {
    final mainPost = mainPostOf(scene);
    final mainAccount = accountOf(scene, mainPost.accountId);
    final quotedPost = quotedPostOf(scene);
    final quotedAccount = quotedPost == null
        ? null
        : accountOf(scene, quotedPost.accountId);

    return SingleChildScrollView(
      child: PostCard(
        post: mainPost,
        account: mainAccount,
        variant: PostCardVariant.detail,
        quotedChild: quotedPost == null || quotedAccount == null
            ? null
            : PostCard(post: quotedPost, account: quotedAccount),
      ),
    );
  }
}

class _TimelineContent extends StatelessWidget {
  const _TimelineContent({required this.scene});

  final Scene scene;

  @override
  Widget build(BuildContext context) {
    final posts = List<Post>.from(scene.posts)
      ..sort((a, b) => a.order.compareTo(b.order));

    if (posts.isEmpty) {
      return Center(
        child: Text(
          '投稿がありません',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      itemCount: posts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final post = posts[index];
        final account = accountOf(scene, post.accountId);
        return PostCard(post: post, account: account);
      },
    );
  }
}
