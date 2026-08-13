import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_spacing.dart';
import '../models/post.dart';
import '../utils/post_time_formatter.dart';

/// 投稿(Post)1件分の編集フォーム(本文・返信数・リポスト数・いいね数・表示回数・日時)。
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
  late final TextEditingController _viewController;

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController(text: widget.post.body);
    _replyController = TextEditingController(text: widget.post.replyCountLabel);
    _repostController = TextEditingController(text: widget.post.repostCountLabel);
    _likeController = TextEditingController(text: widget.post.likeCountLabel);
    _viewController = TextEditingController(text: widget.post.viewCountLabel);
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _replyController.dispose();
    _repostController.dispose();
    _likeController.dispose();
    _viewController.dispose();
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
        _PostImagePicker(
          imagePath: widget.post.imagePath,
          onPick: _pickImage,
          onRemove: _removeImage,
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
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _viewController,
                decoration: const InputDecoration(labelText: '表示回数'),
                onChanged: (value) {
                  widget.post.viewCountLabel = value;
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

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => widget.post.imagePath = picked.path);
    widget.onChanged();
  }

  void _removeImage() {
    setState(() => widget.post.imagePath = null);
    widget.onChanged();
  }
}

/// 投稿への添付画像1枚を選択・プレビュー・削除するUI。
class _PostImagePicker extends StatelessWidget {
  const _PostImagePicker({
    required this.imagePath,
    required this.onPick,
    required this.onRemove,
  });

  final String? imagePath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.image_outlined),
        label: const Text('画像を追加'),
      );
    }

    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: GestureDetector(
              onTap: onPick,
              child: Image.file(File(path), fit: BoxFit.cover),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(4),
          child: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.black54,
            child: IconButton(
              padding: EdgeInsets.zero,
              iconSize: 16,
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onRemove,
            ),
          ),
        ),
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
