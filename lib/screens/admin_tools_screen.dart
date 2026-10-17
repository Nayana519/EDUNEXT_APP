import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'admin_setup_screen.dart';
import 'import_screen.dart';

class AdminToolsScreen extends StatelessWidget {
  const AdminToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    Widget tile(String title, String sub, IconData icon, Widget page) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
                backgroundColor: c.ink, child: Icon(icon, color: c.onInk, size: 20)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(sub, style: TextStyle(color: c.slate, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Admin tools')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        tile('Academic setup', 'Semesters, classes, teachers, subjects',
            Icons.account_tree, const AdminSetupScreen()),
        tile('Import class lists', 'Students and their class (paste CSV or Excel)',
            Icons.groups, const ImportScreen(kind: 'students')),
        tile('Import subject selections', 'Who takes which subject, including electives',
            Icons.fact_check, const ImportScreen(kind: 'enrollments')),
      ]),
    );
  }
}