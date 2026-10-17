import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'coming_soon_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'subjects_screen.dart';

class MainShell extends StatefulWidget {
  final Map<String, dynamic>? me;
  const MainShell({super.key, this.me});
  @override
  State<MainShell> createState() => _MainShellState();
}
class _MainShellState extends State<MainShell> {
  int _index = 0;
  late final Future<Map<String, dynamic>> _me =
    widget.me != null ? Future.value(widget.me!) : ApiService.getMe();

  static const _items = [
    ('Home', Icons.home_outlined),
    ('Subjects', Icons.menu_book_outlined),
    ('Search', Icons.search),
    ('Assistant', Icons.auto_awesome_outlined),
    ('Profile', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return FutureBuilder<Map<String, dynamic>>(
      future: _me,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${snap.error}')));
        }
        final me = snap.data!;
        final role = me['role'] ?? 'student';
        final pages = [
          HomeScreen(me: me),
          SubjectsScreen(role: role),
          const ComingSoonScreen(title: 'Search'),
          const ComingSoonScreen(title: 'Assistant'),
          ProfileScreen(me: me),
        ];
        return Scaffold(
          body: SafeArea(child: IndexedStack(index: _index, children: pages)),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: c.card,
              border: Border(top: BorderSide(color: c.rule)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  for (int i = 0; i < _items.length; i++)
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _index = i),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_items[i].$2,
                              size: 22, color: _index == i ? c.ink : c.slate),
                          const SizedBox(height: 3),
                          Text(_items[i].$1,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: _index == i ? FontWeight.w600 : FontWeight.w500,
                                  color: _index == i ? c.ink : c.slate)),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}