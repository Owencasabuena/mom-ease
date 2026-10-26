import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/screens/auth_screen.dart';
import '../../auth/services/auth_provider.dart';
import '../../journal/providers/journal_provider.dart';
import '../../settings/screens/about_screen.dart';
import '../../settings/services/theme_provider.dart';
import '../widgets/change_pin_dialog.dart';
import '../widgets/change_username_dialog.dart';
import '../widgets/delete_account_dialog.dart';

/// Comprehensive Profile & Settings screen.
/// Dynamically tailors options depending on whether the user is in Local or Google mode.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showChangeUsernameDialog(BuildContext context, String currentName) {
    showDialog(
      context: context,
      builder: (_) => ChangeUsernameDialog(currentName: currentName),
    );
  }

  void _showChangePinDialog(BuildContext context, bool hasExistingPin) {
    showDialog(
      context: context,
      builder: (_) => ChangePinDialog(hasExistingPin: hasExistingPin),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const DeleteAccountDialog());
  }

  void _toggleJournalLock(BuildContext context, bool enable) async {
    final journalProvider = Provider.of<JournalProvider?>(
      context,
      listen: false,
    );
    if (journalProvider == null) return;

    if (enable) {
      final pinController = TextEditingController();
      final formKey = GlobalKey<FormState>();
      final pin = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Set Journal Lock PIN'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set a 4-digit PIN to secure your private journal entries.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: '••••',
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length != 4) {
                      return 'PIN must be 4 digits';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.of(ctx).pop(pinController.text.trim());
                }
              },
              child: const Text('Enable Lock'),
            ),
          ],
        ),
      );

      if (pin != null && pin.isNotEmpty && context.mounted) {
        await journalProvider.saveLockPin(pin);
        await journalProvider.setLockEnabled(true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Journal Lock enabled with PIN.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      final pinController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Disable Journal Lock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your current PIN to turn off Journal Lock:'),
              const SizedBox(height: 16),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '••••',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final valid = await journalProvider.verifyAndUnlock(
                  pinController.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop(valid);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        await journalProvider.setLockEnabled(false);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Journal Lock disabled.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (confirmed == false && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN. Journal Lock remains active.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleGoogleUpgrade(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.continueWithGoogle();

    if (!context.mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account successfully linked to Google!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            Icons.cloud_off_rounded,
            size: 36,
            color: Theme.of(ctx).colorScheme.primary,
          ),
          title: const Text('Connect Google Account'),
          content: Text(
            auth.errorMessage ??
                'Google Sign-In requires Firebase configuration.\n'
                    'In future versions, linking your Google account will back up your local profile securely to the cloud.',
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
    }
  }

  void _handleGoogleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out of Google?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = context.read<AuthProvider>();
      await auth.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  void _showManageGoogleAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.account_circle_outlined, size: 36),
        title: const Text('Manage Google Account'),
        content: const Text(
          'Your profile picture, email, and password are secure and managed '
          'directly through your Google Account settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final current = themeProvider.themeMode;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final activeColor = Theme.of(ctx).colorScheme.primary;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Choose Appearance',
                    style: Theme.of(ctx).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.brightness_auto_rounded),
                  title: const Text('System Default'),
                  subtitle: const Text('Matches your phone settings'),
                  trailing: current == ThemeMode.system
                      ? Icon(Icons.check_circle_rounded, color: activeColor)
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.system);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.light_mode_rounded),
                  title: const Text('Light'),
                  subtitle: const Text('Soft and comforting daytime palette'),
                  trailing: current == ThemeMode.light
                      ? Icon(Icons.check_circle_rounded, color: activeColor)
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.light);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.dark_mode_rounded),
                  title: const Text('Dark'),
                  subtitle: const Text(
                    'Gentle on tired eyes during night feeds',
                  ),
                  trailing: current == ThemeMode.dark
                      ? Icon(Icons.check_circle_rounded, color: activeColor)
                      : const Icon(Icons.circle_outlined),
                  onTap: () {
                    themeProvider.setThemeMode(ThemeMode.dark);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Privacy & Data Policy',
                    style: Theme.of(ctx).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'MomEase treats postpartum privacy with the utmost sanctity. '
                'When you use a local account, no trackers, telemetry, or external servers '
                'store your name, notes, or entries. Everything stays inside this application '
                'and secure storage on your phone.',
                style: Theme.of(ctx).textTheme.bodyMedium
                    ?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.currentUser;

    final displayName = user?.displayName ?? 'Mama';
    final isLocal = user?.isLocal ?? true;
    final accountTypeLabel = isLocal ? 'Local Account' : 'Google Account';

    // Theme label text
    String themeLabel;
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        themeLabel = 'Light';
        break;
      case ThemeMode.dark:
        themeLabel = 'Dark';
        break;
      case ThemeMode.system:
        themeLabel = 'System Default';
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Profile Card ---
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 22.0,
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            backgroundImage:
                                (user?.photoUrl != null &&
                                    user!.photoUrl!.isNotEmpty)
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child:
                                (user?.photoUrl == null ||
                                    user!.photoUrl!.isEmpty)
                                ? Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : 'M',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Username
                          Text(
                            displayName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),

                          if (!isLocal && user?.email != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              user!.email!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 10),

                          // Account Type Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isLocal
                                  ? theme.colorScheme.secondaryContainer
                                        .withValues(alpha: 0.5)
                                  : theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isLocal
                                    ? theme.colorScheme.secondary.withValues(
                                        alpha: 0.4,
                                      )
                                    : theme.colorScheme.primary.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLocal
                                      ? Icons.phone_android_rounded
                                      : Icons.g_mobiledata_rounded,
                                  size: 16,
                                  color: isLocal
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  accountTypeLabel,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isLocal
                                        ? theme.colorScheme.secondary
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Section 1: Account Settings ---
                  _SectionHeader(title: 'Account'),

                  Card(
                    child: Column(
                      children: [
                        if (isLocal) ...[
                          // Local: Change Username
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const Text('Change Username'),
                            subtitle: Text('Current: $displayName'),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () =>
                                _showChangeUsernameDialog(context, displayName),
                          ),
                          const Divider(),

                          // Local: Change PIN
                          ListTile(
                            leading: const Icon(Icons.lock_outline_rounded),
                            title: const Text('Change Local Password / PIN'),
                            subtitle: Text(
                              (user?.hasPin == true)
                                  ? 'PIN protection active'
                                  : 'No PIN set (optional)',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showChangePinDialog(
                              context,
                              user?.hasPin ?? false,
                            ),
                          ),
                          const Divider(),

                          // Local: Sign in with Google (upgrade / connect)
                          ListTile(
                            leading: const Icon(Icons.cloud_upload_outlined),
                            title: const Text('Sign in with Google'),
                            subtitle: const Text(
                              'Connect a Google account to backup data',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _handleGoogleUpgrade(context),
                          ),
                          const Divider(),

                          // Local: Delete Local Account
                          ListTile(
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: theme.colorScheme.error,
                            ),
                            title: Text(
                              'Delete Local Account',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Remove your local profile from this device',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showDeleteAccountDialog(context),
                          ),
                        ] else ...[
                          // Google: Account Information
                          ListTile(
                            leading: const Icon(Icons.info_outline_rounded),
                            title: const Text('Google Account Details'),
                            subtitle: Text(
                              user?.email ?? 'Connected with Google',
                            ),
                          ),
                          const Divider(),

                          // Google: Manage Account
                          ListTile(
                            leading: const Icon(Icons.manage_accounts_outlined),
                            title: const Text('Manage Google Account'),
                            subtitle: const Text(
                              'Profile & credentials managed via Google',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () =>
                                _showManageGoogleAccountDialog(context),
                          ),
                          const Divider(),

                          // Google: Sign Out
                          ListTile(
                            leading: Icon(
                              Icons.logout_rounded,
                              color: theme.colorScheme.error,
                            ),
                            title: Text(
                              'Sign Out',
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Sign out of your Google account',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _handleGoogleSignOut(context),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Section 2: Preferences & Appearance ---
                  _SectionHeader(title: 'Preferences'),

                  Card(
                    child: Column(
                      children: [
                        // Appearance / Theme
                        ListTile(
                          leading: const Icon(Icons.palette_outlined),
                          title: const Text('Theme'),
                          subtitle: Text(themeLabel),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showThemeSelector(context),
                        ),
                        const Divider(),

                        // Notifications (Placeholder)
                        ListTile(
                          leading: const Icon(Icons.notifications_outlined),
                          title: const Text('Notifications'),
                          subtitle: const Text(
                            'Gentle reminders (Coming soon)',
                          ),
                          trailing: Switch(
                            value: false,
                            onChanged: (val) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Notification reminders will be available in an upcoming update.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),

                        // Privacy
                        ListTile(
                          leading: const Icon(Icons.shield_outlined),
                          title: const Text('Privacy & Security'),
                          subtitle: const Text('On-device data guarantee'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showPrivacyInfo(context),
                        ),
                        const Divider(),

                        // Journal App Lock
                        Builder(
                          builder: (context) {
                            final journalProvider =
                                Provider.of<JournalProvider?>(context);
                            final isLockEnabled =
                                journalProvider?.isLockEnabled ?? false;
                            return ListTile(
                              leading: const Icon(Icons.lock_person_outlined),
                              title: const Text('Journal Lock'),
                              subtitle: Text(
                                isLockEnabled
                                    ? 'PIN protection active'
                                    : 'Off (protect entries with 4-digit PIN)',
                              ),
                              trailing: Switch(
                                value: isLockEnabled,
                                onChanged: (enabled) =>
                                    _toggleJournalLock(context, enabled),
                              ),
                            );
                          },
                        ),
                        const Divider(),

                        // About MomEase
                        ListTile(
                          leading: const Icon(Icons.spa_outlined),
                          title: const Text('About MomEase'),
                          subtitle: const Text('Mission & app details'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AboutScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface
              .withValues(alpha: 0.65),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
