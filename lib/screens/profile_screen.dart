import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/edu_top_bar.dart';
import 'help_screen.dart';
import 'linked_classes_screen.dart';
import 'admin_tools_screen.dart';
import 'my_classes_screen.dart';
class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> me;
  const ProfileScreen({super.key, required this.me});

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    final email = (me['email'] ?? '') as String;
    final name = (me['name'] ?? email.split('@').first) as String;
    final role = (me['role'] ?? 'student') as String;
    final initials = name.isEmpty ? '?' : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();

    const themes = [
      ('light', 'Light', Icons.wb_sunny_outlined),
      ('dark', 'Dark', Icons.nightlight_outlined),
      ('girly', 'Girly 🩷', Icons.auto_awesome),
    ];

    return Scaffold(
      body: ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 24), children: [
        const EduTopBar(title: 'Profile', showBell: false),
        Row(children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: c.ink,
            child: Text(initials,
                style: TextStyle(color: c.onInk, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text('${role[0].toUpperCase()}${role.substring(1)} · $email',
                  style: TextStyle(fontSize: 12.5, color: c.slate)),
            ]),
          ),
        ]),
        const SizedBox(height: 22),
        const Text('Appearance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ValueListenableBuilder<String>(
          valueListenable: themeNotifier,
          builder: (context, current, _) => Row(children: [
            for (final t in themes)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => themeNotifier.value = t.$1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: current == t.$1 ? c.ink : c.card,
                        border: Border.all(color: current == t.$1 ? c.ink : c.rule),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(children: [
                        Icon(t.$3, size: 18, color: current == t.$1 ? c.onInk : c.charcoal),
                        const SizedBox(height: 5),
                        Text(t.$2,
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: current == t.$1 ? c.onInk : c.charcoal)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 22),
        const Text('Settings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
         if (me['is_admin'] == true)
          _SettingsRow(
            label: 'Admin tools',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminToolsScreen())),
          ),
        if (me['is_admin'] == true || me['is_advisor'] == true)
          _SettingsRow(
            label: 'My classes',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MyClassesScreen())),
          ),
                _SettingsRow(
          label: 'Notification preferences',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification settings are coming soon.'))),
        ),
        _SettingsRow(
          label: 'Linked classes',
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => LinkedClassesScreen(role: role))),
        ),
        _SettingsRow(
          label: 'Change password',
          onTap: () => _changePassword(context),
        ),
        _SettingsRow(
          label: 'Help and support',
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const HelpScreen())),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
          },
          child: const Text('Sign out'),
        ),
      ]),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SettingsRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(label, style: const TextStyle(fontSize: 13.5)),
              Icon(Icons.chevron_right, size: 18, color: c.slate),
            ]),
          ),
        ),
      ),
    );
  }
}

Future<void> _changePassword(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  final messenger = ScaffoldMessenger.of(context);
  if (user == null || user.email == null) return;

  final usesPassword = user.providerData.any((p) => p.providerId == 'password');
  if (!usesPassword) {
    messenger.showSnackBar(const SnackBar(
        content: Text('You signed in with Google, so there is no password to change.')));
    return;
  }

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Change password'),
      content: Text('We will send a password reset link to ${user.email}.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send link')),
      ],
    ),
  );
  if (ok != true) return;

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
    messenger.showSnackBar(SnackBar(content: Text('Reset link sent to ${user.email}')));
  } on FirebaseAuthException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message ?? 'Could not send the email.')));
  }
}