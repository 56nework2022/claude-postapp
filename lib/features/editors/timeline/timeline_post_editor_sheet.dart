import 'package:flutter/material.dart';

import '../../../constants/app_spacing.dart';
import '../../../models/account.dart';
import '../../../models/post.dart';
import '../../../providers/editor_providers.dart';
import '../../../widgets/post_fields_form.dart';
import '../../account/account_editor_sheet.dart';

/// タイムライン上の投稿1件を編集するボトムシート。
///
/// [post]・[account] は直接ミューテートし、変更のたびに[notifier]の`commit()`で
/// Hiveへ保存する。閉じるボタンで戻るだけで、編集内容はその都度保存済み。
class TimelinePostEditorSheet extends StatelessWidget {
  const TimelinePostEditorSheet({
    super.key,
    required this.post,
    required this.account,
    required this.notifier,
  });

  final Post post;
  final Account account;
  final TimelineEditorNotifier notifier;

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
                  if (updated != null) await notifier.commit();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              PostFieldsForm(post: post, onChanged: notifier.commit),
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
