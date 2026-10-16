import 'package:flutter/material.dart';
import 'home_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final String role;

  const MainNavigationShell({super.key, required this.role});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Nav view matrix array parameters mirroring the full specification map
    final List<Widget> tabs = [
      HomeScreen(role: widget.role),
      const Center(child: Text('📚 Complete Core Subjects List View')),
      const Center(child: Text('🔍 Contextual Search Interface Platform')),
      const Center(child: Text('✨ AI Copilot Engine Chat Interface')),
      const Center(child: Text('👤 Profile Preferences & Appearance Settings')),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'EduNexus',
          style: TextStyle(color: Color(0xFF1E2A44), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Color(0xFF1E2A44)),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: tabs[_selectedIndex],
      
      // PERSISTENT ACCESSIBLE BOTTOM NAVIGATION BAR
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1E2A44).withOpacity(0.1),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Subjects'),
          NavigationDestination(icon: Icon(Icons.search), selectedIcon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'Assistant'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
