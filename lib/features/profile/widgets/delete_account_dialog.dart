import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/screens/auth_screen.dart';
import '../../auth/services/auth_provider.dart';

/// Explicit confirmation dialog before deleting local profile and data.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);
    final auth = context.read<AuthProvider>();
    await auth.deleteAccount();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        Icons.warning_amber_rounded,
        size: 38,
        color: theme.colorScheme.error,
      ),
      title: const Text('Delete local account?'),
      content: Text(
        'This will remove your locally stored MomEase profile from this device.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: _isDeleting ? null : _handleDelete,
          child: _isDeleting
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onError,
                  ),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}
