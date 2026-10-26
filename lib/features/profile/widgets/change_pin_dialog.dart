import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/services/auth_provider.dart';

/// Dialog to update, create, or remove the local PIN.
class ChangePinDialog extends StatefulWidget {
  final bool hasExistingPin;

  const ChangePinDialog({super.key, required this.hasExistingPin});

  @override
  State<ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends State<ChangePinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();

    final success = await auth.updatePin(
      oldPin: widget.hasExistingPin ? _currentPinController.text.trim() : null,
      newPin: _newPinController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      Navigator.of(context).pop();
      final msg = _newPinController.text.isEmpty
          ? 'PIN removed successfully.'
          : 'PIN updated successfully.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Failed to update PIN.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.hasExistingPin ? 'Change Local PIN' : 'Set Local PIN'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.hasExistingPin) ...[
                const Text(
                  'Enter your current PIN to verify your identity:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentPinController,
                  obscureText: _obscureCurrent,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: 'Current PIN',
                    prefixIcon: const Icon(Icons.lock_clock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Current PIN is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              Text(
                widget.hasExistingPin
                    ? 'Enter your new PIN (leave blank to remove PIN protection):'
                    : 'Choose a PIN of at least 4 digits/characters:',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPinController,
                obscureText: _obscureNew,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: widget.hasExistingPin ? 'New PIN' : 'PIN',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.length < 4) {
                    return 'PIN must be at least 4 characters';
                  }
                  if (!widget.hasExistingPin && (val == null || val.isEmpty)) {
                    return 'Please enter a PIN or tap Cancel';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: _newPinController,
                builder: (context, _) {
                  if (_newPinController.text.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: [
                      TextFormField(
                        controller: _confirmPinController,
                        obscureText: _obscureConfirm,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm New PIN',
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (_newPinController.text.isNotEmpty &&
                              val != _newPinController.text) {
                            return 'PINs do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
