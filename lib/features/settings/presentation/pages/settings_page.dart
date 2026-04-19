import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:viralflow_automation/app/app_theme.dart';
import 'package:viralflow_automation/core/providers/providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _autoSchedule = true;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings ⚙️')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            userAsync.when(
              data: (user) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'V',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(user.email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  user.plan.toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: Colors.white),
                      onPressed: _showEditProfileDialog,
                    ),
                  ],
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox(),
            ),
            const SizedBox(height: 24),

            // Credits Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt_rounded, color: AppTheme.accentColor),
                          const SizedBox(width: 8),
                          const Text('Credits Remaining', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text('186 / 200', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 186 / 200,
                      minHeight: 8,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.go('/subscription'),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Get More Credits'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Connected Accounts
            const Text('Connected Accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ref.watch(connectedPlatformsProvider).when(
              data: (connectedList) {
               final connectedSet = connectedList.map((e) => e['platform'] as String).toSet();
                
               return Column(
                  children: [
                    _ConnectedAccountTile(
                      icon: Icons.camera_alt_rounded,
                      name: 'Instagram',
                      color: const Color(0xFFE1306C),
                      isConnected: connectedSet.contains('instagram'),
                      onToggle: () {
                        if (connectedSet.contains('instagram')) {
                          ref.read(oauthServiceProvider).disconnectPlatform('instagram');
                        } else {
                          ref.read(oauthServiceProvider).connectPlatform('instagram');
                        }
                        ref.invalidate(connectedPlatformsProvider);
                      },
                    ),
                    _ConnectedAccountTile(
                      icon: Icons.smart_display_rounded,
                      name: 'YouTube',
                      color: const Color(0xFFFF0000),
                      isConnected: connectedSet.contains('youtube'),
                      onToggle: () {
                         if (connectedSet.contains('youtube')) {
                          ref.read(oauthServiceProvider).disconnectPlatform('youtube');
                        } else {
                          ref.read(oauthServiceProvider).connectPlatform('youtube');
                        }
                        ref.invalidate(connectedPlatformsProvider);
                      },
                    ),
                    _ConnectedAccountTile(
                      icon: Icons.tag_rounded,
                      name: 'Twitter',
                      color: const Color(0xFF1DA1F2),
                      isConnected: connectedSet.contains('twitter'),
                      onToggle: () {
                         if (connectedSet.contains('twitter')) {
                          ref.read(oauthServiceProvider).disconnectPlatform('twitter');
                        } else {
                          ref.read(oauthServiceProvider).connectPlatform('twitter');
                        }
                        ref.invalidate(connectedPlatformsProvider);
                      },
                    ),
                    _ConnectedAccountTile(
                      icon: Icons.work_rounded,
                      name: 'LinkedIn',
                      color: const Color(0xFF0077B5),
                      isConnected: connectedSet.contains('linkedin'),
                      onToggle: () {
                        if (connectedSet.contains('linkedin')) {
                          ref.read(oauthServiceProvider).disconnectPlatform('linkedin');
                        } else {
                          ref.read(oauthServiceProvider).connectPlatform('linkedin');
                        }
                        ref.invalidate(connectedPlatformsProvider);
                      },
                    ),
                    _ConnectedAccountTile(
                      icon: Icons.facebook_rounded,
                      name: 'Facebook',
                      color: const Color(0xFF1877F2),
                      isConnected: connectedSet.contains('facebook'),
                      onToggle: () {
                        if (connectedSet.contains('facebook')) {
                          ref.read(oauthServiceProvider).disconnectPlatform('facebook');
                        } else {
                          ref.read(oauthServiceProvider).connectPlatform('facebook');
                        }
                        ref.invalidate(connectedPlatformsProvider);
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),

            // Preferences
            const Text('Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.notifications_rounded,
              title: 'Push Notifications',
              subtitle: 'Get notified about scheduled posts',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
                activeColor: AppTheme.primaryColor,
              ),
            ),
            _SettingsTile(
              icon: Icons.dark_mode_rounded,
              title: 'Dark Mode',
              subtitle: 'Switch to dark theme',
              trailing: Switch(
                value: _darkMode,
                onChanged: (v) => setState(() => _darkMode = v),
                activeColor: AppTheme.primaryColor,
              ),
            ),
            _SettingsTile(
              icon: Icons.schedule_rounded,
              title: 'Auto-Schedule',
              subtitle: 'AI picks the best time to post',
              trailing: Switch(
                value: _autoSchedule,
                onChanged: (v) => setState(() => _autoSchedule = v),
                activeColor: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // Subscription
            const Text('Subscription', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.workspace_premium_rounded,
              title: 'Upgrade Plan',
              subtitle: 'Get more credits & features',
              onTap: () => context.go('/subscription'),
            ),
            _SettingsTile(
              icon: Icons.receipt_long_rounded,
              title: 'Billing History',
              subtitle: 'View past transactions',
              onTap: () {},
            ),
            const SizedBox(height: 24),

            // Support
            const Text('Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _SettingsTile(
              icon: Icons.help_rounded,
              title: 'Help Center',
              subtitle: 'FAQs and tutorials',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.feedback_rounded,
              title: 'Send Feedback',
              subtitle: 'Help us improve',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.privacy_tip_rounded,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () {},
            ),
            _SettingsTile(
              icon: Icons.description_rounded,
              title: 'Terms of Service',
              subtitle: 'Our terms and conditions',
              onTap: () {},
            ),
            const SizedBox(height: 24),

            // Sign Out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: const BorderSide(color: AppTheme.errorColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // App Version
            Center(
              child: Text('ViralFlow Automation v1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(decoration: const InputDecoration(hintText: 'Bio', prefixIcon: Icon(Icons.info_outline))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authServiceProvider).signOut();
      if (mounted) context.go('/login');
    }
  }
}

class _ConnectedAccountTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final Color color;
  final bool isConnected;
  final VoidCallback onToggle;

  const _ConnectedAccountTile({
    required this.icon,
    required this.name,
    required this.color,
    required this.isConnected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  isConnected ? 'Connected ✓' : 'Not connected',
                  style: TextStyle(fontSize: 12, color: isConnected ? AppTheme.successColor : Colors.grey[500]),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onToggle,
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? Colors.grey.withOpacity(0.1) : color,
              foregroundColor: isConnected ? Colors.grey : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(isConnected ? 'Disconnect' : 'Connect', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),
        onTap: onTap,
      ),
    );
  }
}