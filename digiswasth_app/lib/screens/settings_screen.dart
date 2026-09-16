import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _SectionTitle('Account'),
          _SettingsTile(
            icon: Icons.person_outline,
            title: 'View Profile',
            color: WidgetColors.settings,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            color: WidgetColors.settings,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Security'),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            color: AppColors.primary,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.password,
            title: 'Forgot Password',
            color: AppColors.primary,
            onTap: () {},
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Danger Zone'),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            color: AppColors.danger,
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            color: AppColors.danger,
            onTap: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color == AppColors.danger ? AppColors.danger : AppColors.text,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: AppColors.muted),
    );
  }
}