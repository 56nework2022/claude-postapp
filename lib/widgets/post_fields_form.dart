import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';
import '../models/post.dart';
import '../utils/post_time_formatter.dart';

/// 投稿(Post)1件分の編集フォーム(本文・返信数・リポスト数・いいね数・日時)。
///
/// [post] のフィールドを直接ミューテートし、変更のたびに[onChanged]を呼び出す。
/// Hiveへの保存やプレビューの再描画は呼び出し側(各エディタのNotifier)が担う。
/// 投稿詳細エディタ(メイン投稿・引用ポスト)とタイムラインエディタの両方で共用する。
class PostFieldsForm extends StatefulWidget {
  const PostFieldsForm({
    super.key,
    required this.post,
    required this.onChanged,
    this.title = '投稿内容',
  });

  final Post post;
  final VoidCallback onChanged;
  final String title;

  @override
  State<PostFieldsForm> createState() => _PostFieldsFormState();
}

class _PostFieldsFormState extends State<PostFieldsForm> {
  late final TextEditingController _bodyController;
  late final TextEditingController _replyController;
  late final TextEditingController _repostController;
  late final TextEditingController _likeController;

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController(text: widget.post.body);
    _replyController = TextEditingController(text: widget.post.replyCountLabel);
    _repostController = TextEditingController(text: widget.post.repostCountLabel);
    _likeController = TextEditingController(text: widget.post.likeCountLabel);
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _replyController.dispose();
    _repostController.dispose();
    _likeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _bodyController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: '本文'),
          onChanged: (value) {
            widget.post.body = value;
            widget.onChanged();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyController,
                decoration: const InputDecoration(labelText: '返信数'),
                onChanged: (value) {
                  widget.post.replyCountLabel = value;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _repostController,
                decoration: const InputDecoration(labelText: 'リポスト数'),
                onChanged: (value) {
                  widget.post.repostCountLabel = value;
                  widget.onChanged();
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _likeController,
                decoration: const InputDecoration(labelText: 'いいね数'),
                onChanged: (value) {
                  widget.post.likeCountLabel = value;
                  widget.onChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _DateTimeField(post: widget.post, onChanged: widget.onChanged),
      ],
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.post, required this.onChanged});

  final Post post;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.schedule_outlined),
      title: const Text('日時'),
      subtitle: Text(formatAbsoluteDateTime(post.postedAt)),
      onTap: () => _pickDateTime(context),
    );
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: post.postedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(post.postedAt),
    );
    if (time == null) return;

    post.postedAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    onChanged();
  }
}
