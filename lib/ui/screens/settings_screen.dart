import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../state/auth_state.dart';
import '../../state/theme_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthState>();
    final themeState = context.watch<ThemeState>();

    String themeStr = 'System default';
    if (themeState.themeMode == ThemeMode.light) {
      themeStr = 'Light Mode';
    } else if (themeState.themeMode == ThemeMode.dark) {
      themeStr = 'Dark Mode';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Guidelines'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: General
          const Text(
            'General',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          
          ListTile(
            leading: const Icon(Icons.brightness_medium_outlined),
            title: const Text('Theme Selection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text('Current theme: $themeStr', style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _showThemeSelectionDialog(context, themeState),
          ),
          const Divider(),

          // Section: Legal & Policies
          const SizedBox(height: 16),
          const Text(
            'Legal & Guidelines',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: const Text('Community Guidelines', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Learn what is allowed and how moderation works.', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _showDialogText(
              context,
              'Community Guidelines',
              'Welcome to UNSAID. To maintain honest yet professional dialogue:\n\n'
              '1. Anonymous-First: You represent yourself under an auto-generated pseudonym. Never share credentials.\n'
              '2. No Personal Doxxing: Do not name managers, colleagues, customers, or specific individuals in reviews.\n'
              '3. Anonymity Defaults: Named company profiles are disabled. General category profiling prevents specific firm identification.\n'
              '4. Keep it True: Share real professional experiences. Avoid malicious fabrications or marketing promotion.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Read about internal-only account separations.', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _showDialogText(
              context,
              'Privacy Policy',
              'Internal Account Information Separation:\n\n'
              'UNSAID stores your registration email internally solely for security, abuse control, account recovery, and moderation audit trails.\n\n'
              'Publicly, your email is never linked, displayed, or serialized inside API responses. All public postings, reviews, ratings, and comments are mapped strictly to your pseudonymous profile. No tracking cookie maps your real email to stories externally.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: const Text('Platform responsibilities and legal notices.', style: TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _showDialogText(
              context,
              'Terms of Service',
              'UNSAID is a mock platform built under MVP v1.1 guidelines. Ratings and testimonials are user-contributed opinions. '
              'The platform does not guarantee factuality. Users are solely responsible for content they publish.',
            ),
          ),
          
          const Divider(),

          // Section: Account Control
          if (authState.isAuthenticated) ...[
            const SizedBox(height: 16),
            const Text(
              'Account Control',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red)),
              subtitle: const Text('Disconnect from this device.', style: TextStyle(fontSize: 11)),
              onTap: () async {
                await authState.logout();
                if (context.mounted) {
                  context.go('/welcome');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out successfully.')),
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showDialogText(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content, style: const TextStyle(fontSize: 12.5, height: 1.5)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showThemeSelectionDialog(BuildContext context, ThemeState themeState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: themeState.themeMode,
                onChanged: (val) {
                  if (val != null) {
                    themeState.setThemeMode(val);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: themeState.themeMode,
                onChanged: (val) {
                  if (val != null) {
                    themeState.setThemeMode(val);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System default'),
                value: ThemeMode.system,
                groupValue: themeState.themeMode,
                onChanged: (val) {
                  if (val != null) {
                    themeState.setThemeMode(val);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
