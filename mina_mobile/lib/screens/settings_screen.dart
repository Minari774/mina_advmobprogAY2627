import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

// providers
import '../providers/theme_provider.dart';
import '../services/user_service.dart';

// widgets
import '../widgets/custom_text.dart';

// Enhancement 3: settings page that hosts the dark/light mode switch
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        children: [
          ListTile(
            leading: const Icon(Icons.logout),
            title: CustomText(text: 'Log out', fontSize: 16.sp, fontWeight: FontWeight.w600),
            subtitle: const Text('Clear the active session and return to sign in'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text('Do you want to log out of your account?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              );
              if (confirmed != true || !context.mounted) return;
              await UserService().signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
            },
          ),
          SwitchListTile(
            secondary: Icon(
              themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
            ),
            title: CustomText(
              text: 'Dark Mode',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            subtitle: CustomText(
              text: themeProvider.isDark ? 'Currently on' : 'Currently off',
              fontSize: 12.sp,
            ),
            value: themeProvider.isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
        ],
      ),
    );
  }
}
