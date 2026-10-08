import 'package:flutter/material.dart';
import '../models/subject.dart';

class SubjectChip extends StatelessWidget {
  final Subject subject;
  final VoidCallback onTap;

  const SubjectChip({super.key, required this.subject, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        onPressed: onTap,
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: subject.color.withOpacity(0.3), width: 1),
        ),
        avatar: CircleAvatar(backgroundColor: subject.color, radius: 5),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subject.code,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E2A44)),
            ),
            if (subject.unread > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  '${subject.unread}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
