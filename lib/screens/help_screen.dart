import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const supportEmail = 'support@edunex.app'; // put your real email here

  static const _faqs = [
    ('How do I join a class?',
        'Go to Profile > Linked classes > Join class, then enter the subject code your teacher gave you.'),
    ('Why can\'t I post announcements?',
        'Only approved teacher accounts can post. Students can read announcements and see materials.'),
    ('How do I change my password?',
        'Go to Profile > Change password. We send a reset link to your email.'),
    ('I signed in with Google. Do I have a password?',
        'No. Google accounts sign in with Google, so there is no separate password to change.'),
    ('Where do I find notes and assignments?',
        'Open Subjects, choose a subject, then use the Materials and Assignments tabs.'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
      appBar: AppBar(title: const Text('Help and support')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('Common questions',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        for (final f in _faqs)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration:
                BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(10)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(f.$1,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(f.$2, style: TextStyle(color: c.slate, height: 1.4))],
              ),
            ),
          ),
        const SizedBox(height: 18),
        const Text('Still need help?',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: supportEmail));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Support email copied')));
            }
          },
          icon: const Icon(Icons.copy, size: 18),
          label: const Text(supportEmail),
        ),
      ]),
    );
  }
}