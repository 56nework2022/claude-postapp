import 'dart:io';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../models/account.dart';
import '../models/post.dart';
import '../utils/post_time_formatter.dart';

/// [PostCard] の見た目のバリエーション。
///
/// `timeline` はタイムライン画面向けの1行ヘッダー(相対時刻つき)、
/// `detail` は投稿詳細画面向けの大きめヘッダー+絶対日時表示。
enum PostCardVariant { timeline, detail }

/// 投稿1件分のフィード型表示。タイムライン・投稿詳細エディタの両方で共用する。
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.account,
    this.variant = PostCardVariant.timeline,
    this.quotedChild,
  });

  final Post post;
  final Account account;
  final PostCardVariant variant;

  /// 引用ポストとして入れ子表示する子Widget(通常は`PostCardVariant.timeline`の`PostCard`)。
  final Widget? quotedChild;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(post: post, account: account, variant: variant),
          if (post.body.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(post.body, style: Theme.of(context).textTheme.bodyLarge),
          ],
          if (variant == PostCardVariant.detail) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              formatAbsoluteDateTime(post.postedAt),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
          if (post.imagePath != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.file(File(post.imagePath!), fit: BoxFit.cover),
              ),
            ),
          ],
          if (quotedChild != null) ...[
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: quotedChild,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          _Footer(post: post),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.post,
    required this.account,
    required this.variant,
  });

  final Post post;
  final Account account;
  final PostCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final isDetail = variant == PostCardVariant.detail;
    final avatar = CircleAvatar(
      radius: isDetail ? 22 : 18,
      backgroundImage: account.iconImagePath == null
          ? null
          : FileImage(File(account.iconImagePath!)),
      child: account.iconImagePath == null
          ? const Icon(Icons.person)
          : null,
    );

    final nameAndBadge = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            account.displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (account.isVerified)
          const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Icon(Icons.verified, size: 15, color: AppColors.verifiedBadge),
          ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: isDetail
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    nameAndBadge,
                    Text(
                      '@${account.username}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                )
              : Row(
                  children: [
                    nameAndBadge,
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '@${account.username} · ${formatRelativeTime(post.postedAt)}',
                        style: TextStyle(color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FooterItem(icon: Icons.chat_bubble_outline, label: post.replyCountLabel),
        _FooterItem(icon: Icons.repeat, label: post.repostCountLabel),
        _FooterItem(icon: Icons.favorite_border, label: post.likeCountLabel),
        const Spacer(),
        Icon(Icons.ios_share, size: 16, color: Colors.grey.shade600),
      ],
    );
  }
}

class _FooterItem extends StatelessWidget {
  const _FooterItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
