import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/providers/auth_state.dart';

/// Settings and user profile page
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User Profile Section
          if (authState is AuthenticatedState)
            _buildProfileSection(context, ref, authState.user),
          
          const Divider(),
          
          // Account Settings
          _buildSettingsSection(
            'Account',
            [
              _buildSettingsTile(
                context,
                Icons.person_outline,
                'Profile',
                'Edit your profile information',
                () => _navigateToProfile(context),
              ),
              _buildSettingsTile(
                context,
                Icons.privacy_tip_outlined,
                'Privacy',
                'Manage privacy settings',
                () => _showComingSoon(context, 'Privacy settings'),
              ),
              _buildSettingsTile(
                context,
                Icons.security,
                'Security',
                'Two-factor authentication, biometrics',
                () => _showComingSoon(context, 'Security settings'),
              ),
            ],
          ),
          
          const Divider(),
          
          // App Settings
          _buildSettingsSection(
            'App Settings',
            [
              _buildSettingsTile(
                context,
                Icons.notifications_outlined,
                'Notifications',
                'Message and call notifications',
                () => _showComingSoon(context, 'Notification settings'),
              ),
              _buildSettingsTile(
                context,
                Icons.dark_mode_outlined,
                'Theme',
                'Choose app theme',
                () => _showThemeSelector(context),
              ),
              _buildSettingsTile(
                context,
                Icons.language_outlined,
                'Language',
                'Choose app language',
                () => _showComingSoon(context, 'Language settings'),
              ),
            ],
          ),
          
          const Divider(),
          
          // Chat Settings
          _buildSettingsSection(
            'Chat',
            [
              _buildSettingsTile(
                context,
                Icons.backup_outlined,
                'Chat Backup',
                'Backup and restore chats',
                () => _showComingSoon(context, 'Chat backup'),
              ),
              _buildSettingsTile(
                context,
                Icons.storage_outlined,
                'Storage Usage',
                'Manage app storage',
                () => _showComingSoon(context, 'Storage management'),
              ),
            ],
          ),
          
          const Divider(),
          
          // Help & Support
          _buildSettingsSection(
            'Help & Support',
            [
              _buildSettingsTile(
                context,
                Icons.help_outline,
                'Help',
                'Get help and support',
                () => _showComingSoon(context, 'Help center'),
              ),
              _buildSettingsTile(
                context,
                Icons.info_outline,
                'About',
                'App version and information',
                () => _showAboutDialog(context),
              ),
              _buildSettingsTile(
                context,
                Icons.bug_report_outlined,
                'Report a Problem',
                'Send feedback to developers',
                () => _showComingSoon(context, 'Feedback form'),
              ),
            ],
          ),
          
          const Divider(),
          
          // Logout
          _buildLogoutSection(context, ref),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, WidgetRef ref, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF25D366).withOpacity(0.1),
            child: Text(
              user.displayName?.isNotEmpty == true 
                  ? user.displayName![0].toUpperCase()
                  : user.email?[0].toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF25D366),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? 'No name set',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? 'No email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (user.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.phone!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.edit,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF25D366),
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutSection(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.red.withOpacity(0.3)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout),
            SizedBox(width: 8),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    context.push('/auth/profile-setup');
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Theme',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.brightness_auto),
              title: const Text('System Default'),
              trailing: const Icon(Icons.check, color: Color(0xFF25D366)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'WhatsApp Clone',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF25D366),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.chat_bubble,
          color: Colors.white,
          size: 30,
        ),
      ),
      children: [
        const Text(
          'A modern messaging app built with Flutter, featuring real-time chat, '
          'file sharing, and video calling capabilities.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Built with ❤️ using Flutter, Supabase, and LiveKit.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                context.go('/auth');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }
}