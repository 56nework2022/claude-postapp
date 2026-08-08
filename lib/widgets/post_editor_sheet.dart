import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../models/account.dart';
import '../models/post.dart';
import '../features/account/account_editor_sheet.dart';
import 'post_fields_form.dart';

/// 投稿1件を編集するボトムシート。
///
/// [post]・[account] は直接ミューテートし、変更のたびに[onCommit]で
/// Hiveへ保存する。閉じるボタンで戻るだけで、編集内容はその都度保存済み。
class PostEditorSheet extends StatelessWidget {
  const PostEditorSheet({
    super.key,
    required this.post,
    required this.account,
    required this.onCommit,
  });

  final Post post;
  final Account account;
  final Future<void> Function() onCommit;

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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('投稿を編集', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('アカウント設定'),
                subtitle: Text(
                  '${account.displayName} (@${account.username})',
                ),
                onTap: () async {
                  final updated = await showModalBottomSheet<Account>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        AccountEditorSheet(initialAccount: account),
                  );
                  if (updated != null) await onCommit();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              PostFieldsForm(post: post, onChanged: onCommit),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
