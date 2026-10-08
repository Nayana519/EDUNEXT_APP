import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  final String role; // 'teacher' or 'student'

  const DashboardScreen({super.key, required this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Static Data mimicking your reference model arrays
  final List<Map<String, dynamic>> subjects = [
    {'code': 'CS301', 'name': 'Database Systems', 'teacher': 'Dr. Meera Sharma', 'color': 0xFF2F6F4E, 'unread': 2},
    {'code': 'CS302', 'name': 'Operating Systems', 'teacher': 'Dr. Arvind Rao', 'color': 0xFF3E6E9E, 'unread': 0},
    {'code': 'CS303', 'name': 'Computer Networks', 'teacher': 'Prof. Kavya Iyer', 'color': 0xFFE2963A, 'unread': 1},
    {'code': 'CS304', 'name': 'Software Engineering', 'teacher': 'Dr. Meera Sharma', 'color': 0xFF7A4B6B, 'unread': 0},
  ];

  final List<Map<String, dynamic>> feed = [
    {'code': 'CS301', 'title': 'Assignment 3 uploaded', 'body': 'Covers normalization up to 3NF. Submit as a single PDF.', 'time': '2h ago', 'tag': 'Deadline: 22 Sep', 'color': 0xFF2F6F4E},
    {'code': 'Class', 'title': 'Mid-semester exam schedule', 'body': 'Room allocations are posted outside the HOD office.', 'time': '5h ago', 'tag': null, 'color': 0xFF1E2A44},
    {'code': 'CS303', 'title': 'Voice note: lab rescheduled', 'body': 'Transcribed: "Friday\'s networking lab moves to Monday."', 'time': 'Yesterday', 'tag': 'Auto-transcribed', 'color': 0xFFE2963A},
  ];

  @override
  Widget build(BuildContext context) {
    // Navigation items mirroring your React file specification
    final List<Widget> screens = [
      _buildHomeTab(),
      _buildSubjectsTab(),
      _buildSearchTab(),
      _buildAssistantTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'EduNexus',
          style: TextStyle(color: Color(0xFF1E2A44), fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF1E2A44)),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 9)),
                ),
              )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: screens[_currentIndex],
      
      // Dynamic Functional Floating Action Button for Teachers
      floatingActionButton: widget.role == 'teacher' && _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showAddClassDialog,
              backgroundColor: const Color(0xFF2F6F4E),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Class', style: TextStyle(color: Colors.white)),
            )
          : null,
          
      // Permanent Scannable Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E2A44),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'Subjects'),
          BottomNavigationBarItem(icon: Icon(Icons.search), activeIcon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'Assistant'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // 1. Home Dashboard View Component
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.role == 'teacher' ? 'Your Classes' : 'Enrolled Subjects',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2A44)),
          ),
          const SizedBox(height: 12),
          
          // Horizontal Selector Chips Grid
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final sub = subjects[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Color(sub['color']).withOpacity(0.4)),
                    avatar: CircleAvatar(backgroundColor: Color(sub['color']), radius: 5),
                    label: Text(sub['code'], style: const TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () {},
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Workspace Feed',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E2A44)),
          ),
          const SizedBox(height: 12),
          
          // Feed Cards Stream Render
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: feed.length,
            itemBuilder: (context, index) {
              final item = feed[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE9ECEF)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: Color(item['color']), width: 5)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['code'], style: TextStyle(color: Color(item['color']), fontWeight: FontWeight.bold)),
                          Text(item['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(item['body'], style: const TextStyle(color: Colors.black87)),
                      if (item['tag'] != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF1F3F5), borderRadius: BorderRadius.circular(4)),
                          child: Text(item['tag'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                        )
                      ]
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Placeholder Shells for alternate structural navbar tabs
  Widget _buildSubjectsTab() => const Center(child: Text('📚 Subjects Curriculums Directory'));
  Widget _buildSearchTab() => const Center(child: Text('🔍 Contextual Search Interface'));
  Widget _buildAssistantTab() => const Center(child: Text('✨ AI Copilot Workspaces'));
  Widget _buildProfileTab() => const Center(child: Text('👤 User Settings Profiles'));

  // Action Logic implementation method
  void _showAddClassDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Class Instance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Subject Name (e.g. Compiler Design)')),
            TextField(decoration: const InputDecoration(labelText: 'Subject Code (e.g. CS401)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Create')),
        ],
      ),
    );
  }
}
