import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils.dart';
import '../widgets/feed_card.dart';
import 'roster_screen.dart';

class SubjectDetailScreen extends StatelessWidget {
  final Map<String, dynamic> subject;
  final String role;
  const SubjectDetailScreen({super.key, required this.subject, required this.role});

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    final color = hexToColor(subject['color']);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(children: [
          Container(
            width: double.infinity,
            color: color,
            padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 4, 16, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                if (role == 'teacher')
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RosterScreen(subject: subject))),
                    icon: const Icon(Icons.groups, color: Colors.white),
                    label: const Text('Students', style: TextStyle(color: Colors.white)),
                  ),
              ]),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(subject['code'],
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subject['name'],
                      style: const TextStyle(
                          fontFamily: 'serif',
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
          TabBar(
            labelColor: c.charcoal,
            unselectedLabelColor: c.slate,
            indicatorColor: color,
            dividerColor: c.rule,
            tabs: const [Tab(text: 'Feed'), Tab(text: 'Materials'), Tab(text: 'Assignments')],
          ),
          Expanded(
            child: TabBarView(children: [
              _FeedTab(subjectId: subject['id']),
              _MaterialsTab(subjectId: subject['id'], color: color, isTeacher: role == 'teacher'),
              Center(child: Text('No assignments yet', style: TextStyle(color: c.slate))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _FeedTab extends StatelessWidget {
  final String subjectId;
  const _FeedTab({required this.subjectId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getFeed(subjectId: subjectId),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (snap.data!.isEmpty) {
          return Center(
              child: Text('No announcements yet', style: TextStyle(color: context.edu.slate)));
        }
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [for (final p in snap.data!) FeedCard(post: p)],
        );
      },
    );
  }
}

class _MaterialsTab extends StatelessWidget {
  final String subjectId;
  final Color color;
  final bool isTeacher;
  const _MaterialsTab({required this.subjectId, required this.color, required this.isTeacher});

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              backgroundColor: c.chalk,
              foregroundColor: Colors.white,
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('File picker coming soon'))),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            )
          : null,
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getMaterials(subjectId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (snap.data!.isEmpty) {
            return Center(child: Text('No materials yet', style: TextStyle(color: c.slate)));
          }
          return ListView(padding: const EdgeInsets.all(18), children: [
            for (final m in snap.data!)
              Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(12),
                decoration:
                    BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Icon(Icons.description_outlined, size: 20, color: color),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m['name'],
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                          '${m['page_count']} pages · ${m['has_text'] == true ? 'indexed for search' : 'no text found'}',
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