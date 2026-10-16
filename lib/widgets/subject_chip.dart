import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils.dart';

class SubjectChip extends StatelessWidget {
  final Map<String, dynamic> subject;
  final VoidCallback? onTap;
  const SubjectChip({super.key, required this.subject, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(color: c.rule),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: hexToColor(subject['color']), shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(subject['code'], style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}