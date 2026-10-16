import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils.dart';
import 'subject_detail_screen.dart';

class SubjectsScreen extends StatelessWidget {
  final String role;
  const SubjectsScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subjects')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getSubjects(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final subjects = snap.data!;
          if (subjects.isEmpty) return const Center(child: Text('No subjects yet'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final s in subjects)
                Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: hexToColor(s['color'])),
                    title: Text(s['name']),
                    subtitle: Text(s['code']),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SubjectDetailScreen(subject: s, role: role)),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}