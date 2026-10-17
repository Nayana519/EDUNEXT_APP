import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils.dart';
import '../widgets/edu_top_bar.dart';
import 'subject_detail_screen.dart';

class SubjectsScreen extends StatelessWidget {
  final String role;
  const SubjectsScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
      body: Column(children: [
        const EduTopBar(title: 'Subjects'),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: ApiService.getSubjects(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              final subjects = snap.data!;
              if (subjects.isEmpty) {
                return Center(child: Text('No subjects yet', style: TextStyle(color: c.slate)));
              }
              return ListView(padding: const EdgeInsets.symmetric(horizontal: 18), children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('Your subjects',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                for (final s in subjects)
                  Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    child: Material(
                      color: c.card,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => SubjectDetailScreen(subject: s, role: role))),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: IntrinsicHeight(
                            child: Row(children: [
                              Container(
                                  width: 5,
                                  decoration: BoxDecoration(
                                      color: hexToColor(s['color']),
                                      borderRadius: BorderRadius.circular(3))),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s['name'],
                                          style: const TextStyle(
                                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(s['code'],
                                          style: TextStyle(fontSize: 12, color: c.slate)),
                                    ]),
                              ),
                              Icon(Icons.chevron_right, size: 20, color: c.slate),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
              ]);
            },
          ),
        ),
      ]),
    );
  }
}