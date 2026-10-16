import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils.dart';

class FeedCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const FeedCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    final accent = hexToColor(post['color'] ?? '#1E2A44');
    final tag = post['tag'] as String?;
    final body = (post['body'] ?? '') as String;
    final isVoice = post['type'] == 'voice';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: c.card,
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(width: 4, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(post['subject_code'] ?? 'Class-wide',
                          style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 11.5)),
                      Row(children: [
                        Icon(Icons.access_time, size: 11, color: c.slate),
                        const SizedBox(width: 3),
                        Text(timeAgo(post['created_at'] ?? ''),
                            style: TextStyle(color: c.slate, fontSize: 11)),
                      ]),
                    ]),
                    const SizedBox(height: 5),
                    Row(children: [
                      if (isVoice) ...[
                        Icon(Icons.mic, size: 14, color: c.slate),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(post['title'],
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(body, style: TextStyle(color: c.slate, fontSize: 13, height: 1.45)),
                    ],
                    if (tag != null && tag.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                            color: c.rule, borderRadius: BorderRadius.circular(8)),
                        child: Text(tag,
                            style: TextStyle(color: c.ink, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}