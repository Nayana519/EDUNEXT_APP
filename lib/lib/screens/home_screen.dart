import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/edu_top_bar.dart';
import '../widgets/feed_card.dart';
import '../widgets/subject_chip.dart';
import 'compose_screen.dart';
import 'subject_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> me;
  const HomeScreen({super.key, required this.me});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<dynamic>> _feed = ApiService.getFeed();
  late Future<List<dynamic>> _subjects = ApiService.getSubjects();

  void _refresh() => setState(() {
        _feed = ApiService.getFeed();
        _subjects = ApiService.getSubjects();
      });

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    final role = widget.me['role'] ?? 'student';
    final isTeacher = role == 'teacher';
    final email = (widget.me['email'] ?? '') as String;
    final name = widget.me['name'] ?? email.split('@').first;

    return Scaffold(
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              backgroundColor: c.chalk,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: () async {
                final posted = await Navigator.push<bool>(
                    context, MaterialPageRoute(builder: (_) => const ComposeScreen()));
                if (posted == true) _refresh();
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
          const EduTopBar(title: 'EduNex', wordmark: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_greeting()}, $name',
                  style: const TextStyle(
                      fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(isTeacher ? 'Teacher dashboard' : 'Student dashboard',
                  style: TextStyle(fontSize: 12.5, color: c.slate)),
            ]),
          ),
          SizedBox(
            height: 40,
            child: FutureBuilder<List<dynamic>>(
              future: _subjects,
              builder: (context, snap) {
                final list = snap.data ?? [];
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  children: [
                    for (final s in list)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SubjectChip(
                          subject: s,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SubjectDetailScreen(subject: s, role: role))),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Text(isTeacher ? 'Recent activity' : 'Class feed',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: FutureBuilder<List<dynamic>>(
              future: _feed,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Text('Error: ${snap.error}');
                final posts = snap.data!;
                if (posts.isEmpty) {
                  return Text('No announcements yet', style: TextStyle(color: c.slate));
                }
                return Column(children: [for (final p in posts) FeedCard(post: p)]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}