import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../home/screens/home_screen.dart';
import '../services/auth_provider.dart';

/// Screen allowing new mothers to set up an offline-only local profile.
class LocalSetupScreen extends StatefulWidget {
  const LocalSetupScreen({super.key});

  @override
  State<LocalSetupScreen> createState() => _LocalSetupScreenState();
}

class _LocalSetupScreenState extends State<LocalSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();

    final auth = context.read<AuthProvider>();
    final success = await auth.continueLocally(
      displayName: name,
      pin: pin.isNotEmpty ? pin : null,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Setup failed. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Local Profile Setup')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 20.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Warm Heading
                    Text(
                      'Welcome to MomEase',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a warm, private space tailored to you. Everything stays directly on your device.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.72,
                        ),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Display Name (Required)
                    Text(
                      'What should we call you?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      key: const Key('name_input_field'),
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Sarah or Mama',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name or preferred nickname';
                        }
                        if (value.trim().length < 2) {
                          return 'Name should be at least 2 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    // Optional PIN / Password
                    Row(
                      children: [
                        Text(
                          'Local PIN / Password',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Optional',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add an optional PIN to protect your personal reflections on this device.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('pin_input_field'),
                      controller: _pinController,
                      obscureText: _obscurePin,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        hintText: '4 or more digits / characters',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePin
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePin = !_obscurePin;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            value.length < 4) {
                          return 'PIN must be at least 4 characters if provided';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Confirm PIN Field (shown if user typed something in PIN)
                    AnimatedBuilder(
                      animation: _pinController,
                      builder: (context, _) {
                        if (_pinController.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Confirm PIN / Password',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              key: const Key('confirm_pin_input_field'),
                              controller: _confirmPinController,
                              obscureText: _obscureConfirmPin,
                              decoration: InputDecoration(
                                hintText: 'Re-enter your PIN',
                                prefixIcon: const Icon(
                                  Icons.lock_reset_rounded,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPin
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPin = !_obscureConfirmPin;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (_pinController.text.isNotEmpty &&
                                    value != _pinController.text) {
                                  return 'PINs do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Submit Button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return ElevatedButton(
                          key: const Key('submit_local_setup_btn'),
                          onPressed: auth.isLoading ? null : _submit,
                          child: auth.isLoading
                              ? SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : const Text('Begin My Journey'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
