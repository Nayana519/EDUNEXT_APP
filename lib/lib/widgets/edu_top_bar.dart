import 'package:flutter/material.dart';
import '../screens/notifications_screen.dart';
import '../theme/app_theme.dart';

class EduTopBar extends StatelessWidget {
  final String title;
  final bool wordmark;
  final bool showBell;
  const EduTopBar({super.key, required this.title, this.wordmark = false, this.showBell = true});

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 8, 6),
      child: Row(children: [
        Text(title,
            style: TextStyle(
                fontFamily: 'serif',
                fontSize: wordmark ? 20 : 18,
                fontWeight: FontWeight.w600,
                color: wordmark ? c.ink : c.charcoal)),
        const Spacer(),
        if (showBell)
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
      ]),
    );
  }
}