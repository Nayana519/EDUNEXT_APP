import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils.dart';

class LinkedClassesScreen extends StatefulWidget {
  final String role;
  const LinkedClassesScreen({super.key, required this.role});
  @override
  State<LinkedClassesScreen> createState() => _LinkedClassesScreenState();
}

class _LinkedClassesScreenState extends State<LinkedClassesScreen> {
  late Future<List<dynamic>> _items = ApiService.getSubjects();
  static const _palette = [
    '#2F6F4E', '#3E6E9E', '#E2963A', '#7A4B6B', '#C2185B', '#1E2A44'
  ];

  bool get _isTeacher => widget.role == 'teacher';

  void _reload() => setState(() => _items = ApiService.getSubjects());

  Future<void> _add() async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isTeacher ? 'Add a subject' : 'Join a class'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Subject code (e.g. CS301)'),
          ),
          if (_isTeacher)
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Subject name'),
            ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(_isTeacher ? 'Add' : 'Join')),
        ],
      ),
    );
    if (ok != true) return;

    final code = codeCtrl.text.trim().toUpperCase();
    final name = nameCtrl.text.trim();
    if (code.isEmpty || (_isTeacher && name.isEmpty)) return;

    try {
      if (_isTeacher) {
        final color = _palette[Random().nextInt(_palette.length)];
        await ApiService.createSubject(code, name, color);
      } else {
        await ApiService.joinClass(code);
      }
      _reload();
    } on DioException catch (e) {
      final data = e.response?.data;
      final detail = data is Map ? data['detail'] : null;
      final msg = detail is String ? detail : 'Something went wrong. Try again.';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
      appBar: AppBar(title: const Text('Linked classes')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.chalk,
        foregroundColor: Colors.white,
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(_isTeacher ? 'Add subject' : 'Join class'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _items,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final list = snap.data!;
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _isTeacher
                      ? 'You have no subjects yet. Tap "Add subject".'
                      : 'You are not in any class yet. Tap "Join class" and enter the code from your teacher.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.slate),
                ),
              ),
            );
          }
          return ListView(padding: const EdgeInsets.all(18), children: [
            for (final s in list)
              Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(12),
                decoration:
                    BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  CircleAvatar(radius: 6, backgroundColor: hexToColor(s['color'])),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['name'],
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(s['code'], style: TextStyle(fontSize: 12, color: c.slate)),
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