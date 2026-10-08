import 'package:flutter/material.dart';
import '../models/subject.dart';
import '../models/announcement.dart';
import '../widgets/subject_chip.dart';
import '../widgets/feed_card.dart';
import 'subject_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  final String role;

  const HomeScreen({super.key, required this.role});

  // Mock array states matching the React design spec elements
  final List<Subject> sampleSubjects = const [
    Subject(id: "cs301", code: "CS301", name: "Database Systems", teacher: "Dr. Meera Sharma", color: Color(0xFF2F6F4E), unread: 2),
    Subject(id: "cs302", code: "CS302", name: "Operating Systems", teacher: "Dr. Arvind Rao", color: Color(0xFF3E6E9E), unread: 0),
    Subject(id: "cs303", code: "CS303", name: "Computer Networks", teacher: "Prof. Kavya Iyer", color: Color(0xFFE2963A), unread: 1),
    Subject(id: "cs304", code: "CS304", name: "Software Engineering", teacher: "Dr. Meera Sharma", color: Color(0xFF7A4B6B), unread: 0),
  ];

  final List<Announcement> sampleFeed = const [
    Announcement(id: 1, subjectCode: "CS301", color: Color(0xFF2F6F4E), type: "text", title: "Assignment 3 uploaded", body: "Covers normalization up to 3NF. Submit as a single PDF.", time: "2h ago", tag: "Deadline: 22 Sep"),
    Announcement(id: 2, subjectCode: "Class", color: Color(0xFF1E2A44), type: "text", title: "Mid-semester exam schedule released", body: "Room allocations are posted outside the HOD office.", time: "5h ago"),
    Announcement(id: 3, subjectCode: "CS303", color: Color(0xFFE2963A), type: "voice", title: "Voice note: lab rescheduled", body: "Transcribed: “Friday's networking lab moves to Monday, same time, same lab.”", time: "Yesterday", tag: "Auto-transcribed"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // GREETING CONTAINER
            Text(
              role == 'teacher' ? 'Good morning, Professor' : 'Good morning, Anjali',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E2A44)),
            ),
            const SizedBox(height: 4),
            const Text(
              'B.Tech CSE — Semester 5, Section A',
              style: TextStyle(color: Color(0xFF63697A), fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // DYNAMIC SUBJECT/CLASS SELECTOR CHIPS GRID
            Text(
              role == 'teacher' ? 'Your Active Classes' : 'Enrolled Subjects',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF63697A), letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: sampleSubjects.length,
                itemBuilder: (context, index) {
                  final subject = sampleSubjects[index];
                  return SubjectChip(
                    subject: subject,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectDetailScreen(subject: subject),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // SYSTEM FEED LAYOUT LIST
            const Text(
              'Class Feed Updates',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E2A44)),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sampleFeed.length,
              itemBuilder: (context, index) {
                return FeedCard(item: sampleFeed[index]);
              },
            ),
          ],
        ),
      ),
    );
  }
}
