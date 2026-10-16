import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/announcement.dart';
import '../widgets/feed_card.dart';

class SubjectDetailScreen extends StatelessWidget {
  final Subject subject;

  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E2A44)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(subject.code, style: const TextStyle(color: Color(0xFF1E2A44), fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: subject.color,
            unselectedLabelColor: const Color(0xFF63697A),
            indicatorColor: subject.color,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Feed'),
              Tab(text: 'Materials'),
              Tab(text: 'Assignments'),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // METADATA COURSE CARD HEADER SKELETON
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E2A44)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subject.teacher,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF63697A), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // TAB SCROLL WORKSPACES LAYOUTS
            Expanded(
              child: TabBarView(
                children: [
                  _buildFeedView(),
                  const Center(child: Text('📂 Shared PDF Reference Learning Materials')),
                  const Center(child: Text('📝 Course Assignment Workflow Targets')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedView() {
    final mockTargetFeed = Announcement(
      id: 1,
      subjectCode: subject.code,
      color: subject.color,
      type: "text",
      title: "Assignment 3 uploaded",
      body: "Covers normalization up to 3NF. Submit as a single PDF.",
      time: "2h ago",
      tag: "Deadline: 22 Sep",
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FeedCard(item: mockTargetFeed),
      ],
    );
  }
}
