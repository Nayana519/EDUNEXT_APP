import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils.dart';

class AuditScreen extends StatelessWidget {
  final Map<String, dynamic> subject;
  const AuditScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
      appBar: AppBar(title: Text('${subject['code']} history')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getAudit(subject['id']),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text(apiError(snap.error!)));
          final list = snap.data!;
          if (list.isEmpty) {
            return Center(
                child: Text('No changes recorded yet', style: TextStyle(color: c.slate)));
          }
          return ListView(padding: const EdgeInsets.all(18), children: [
            for (final a in list)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: c.card, borderRadius: BorderRadius.circular(10)),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(
                    a['action'] == 'add' ? Icons.person_add : Icons.person_remove,
                    size: 20,
                    color: a['action'] == 'add' ? c.chalk : c.danger,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        '${a['action'] == 'add' ? 'Added' : 'Removed'} ${a['name']} (${a['register_number']})',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      if ((a['reason'] ?? '').toString().isNotEmpty)
                        Text('Reason: ${a['reason']}',
                            style: TextStyle(fontSize: 12, color: c.slate)),
                      Text('${a['by'] ?? 'system'} · ${timeAgo(a['created_at'])}',
                          style: TextStyle(fontSize: 11.5, color: c.slate)),
                    ]),
                  ),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}