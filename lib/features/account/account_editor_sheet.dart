import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_spacing.dart';
import '../../models/account.dart';

/// アカウント(表示名・ユーザー名・アイコン・認証バッジ)を編集するボトムシート。
///
/// [initialAccount] を直接書き換えて保存し、`Navigator.pop` で呼び出し元へ
/// 返す。呼び出し元(投稿詳細/タイムラインエディタ)への組み込みはタスク6・7で行う。
class AccountEditorSheet extends StatefulWidget {
  const AccountEditorSheet({super.key, required this.initialAccount});

  final Account initialAccount;

  @override
  State<AccountEditorSheet> createState() => _AccountEditorSheetState();
}

class _AccountEditorSheetState extends State<AccountEditorSheet> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _usernameController;
  late String? _iconImagePath;
  late bool _isVerified;

  @override
  void initState() {
    super.initState();
    final account = widget.initialAccount;
    _displayNameController = TextEditingController(text: account.displayName);
    _usernameController = TextEditingController(text: account.username);
    _iconImagePath = account.iconImagePath;
    _isVerified = account.isVerified;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('アカウント設定', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: _IconPicker(imagePath: _iconImagePath, onTap: _pickIcon),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _displayNameController,
              decoration: const InputDecoration(labelText: '表示名'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'ユーザー名',
                prefixText: '@',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('認証バッジ'),
              value: _isVerified,
              onChanged: (value) => setState(() => _isVerified = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: _save, child: const Text('保存')),
          ],
        ),
      ),
    );
  }

  Future<void> _pickIcon() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _iconImagePath = picked.path);
  }

  void _save() {
    final account = widget.initialAccount
      ..displayName = _displayNameController.text.trim()
      ..username = _usernameController.text.trim()
      ..iconImagePath = _iconImagePath
      ..isVerified = _isVerified;
    Navigator.of(context).pop(account);
  }
}

class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.imagePath, required this.onTap});

  final String? imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: imagePath == null
                ? null
                : FileImage(File(imagePath!)),
            child: imagePath == null
                ? const Icon(Icons.person, size: 36)
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.edit,
                size: 14,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
