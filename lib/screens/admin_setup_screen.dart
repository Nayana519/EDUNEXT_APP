import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils.dart';
import '../widgets/prompt.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});
  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  List<dynamic> _sem = [], _cls = [], _tea = [], _sub = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([
        ApiService.adminList('semesters'),
        ApiService.adminList('classes'),
        ApiService.adminList('teachers'),
        ApiService.getSubjects(),
      ]);
      if (!mounted) return;
      setState(() {
        _sem = r[0];
        _cls = r[1];
        _tea = r[2];
        _sub = r[3];
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() { _error = apiError(e); _loading = false; });
    }
  }

  Future<void> _create(String what, Map<String, dynamic> body) async {
    try {
      await ApiService.adminCreate(what, body);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiError(e))));
      }
    }
  }

  Future<void> _addSemester() async {
    final v = await promptFields(
        context, 'New semester', ['Academic year (e.g. 2026-27)', 'Name (e.g. S7)']);
    if (v == null) return;
    _create('semesters', {'academic_year': v[0], 'name': v[1], 'is_current': true});
  }

  Future<void> _addClass() async {
    final v = await promptFields(context, 'New class (current semester)',
        ['Class name (e.g. S7 CSE-D)']);
    if (v == null) return;
    _create('classes', {'name': v[0]});
  }

  Future<void> _addTeacher() async {
    final v = await promptFields(context, 'Approve a teacher', ['Email', 'Name']);
    if (v == null) return;
    _create('teachers', {'email': v[0], 'name': v[1].isEmpty ? null : v[1]});
  }

  Future<void> _addSubject() async {
    final v = await promptFields(context, 'New subject', [
      'Code (e.g. CST401)',
      'Name',
      'Teacher email',
      'Kind: common or elective',
      'Class name (needed for common)',
    ]);
    if (v == null) return;
    _create('subjects', {
      'code': v[0],
      'name': v[1],
      'teacher_email': v[2],
      'kind': v[3].isEmpty ? 'common' : v[3],
      'class_name': v[4].isEmpty ? null : v[4],
    });
  }

  Widget _section(String title, VoidCallback onAdd, List<Widget> items) {
    final c = context.edu;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Row(children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(
              onPressed: onAdd, icon: const Icon(Icons.add, size: 18), label: const Text('Add')),
        ]),
      ),
      if (items.isEmpty) Text('None yet', style: TextStyle(color: c.slate, fontSize: 12.5)),
      ...items,
    ]);
  }

  Widget _row(String title, String sub) {
    final c = context.edu;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        if (sub.isNotEmpty)
          Text(sub, style: TextStyle(fontSize: 11.5, color: c.slate)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
      appBar: AppBar(title: const Text('Academic setup')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: c.danger)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 40), children: [
                    Text('Set up in this order: semester, classes, teachers, subjects.',
                        style: TextStyle(color: c.slate, fontSize: 12.5)),
                    _section('Semesters', _addSemester, [
                      for (final s in _sem)
                        _row('${s['name']} · ${s['academic_year']}',
                            s['is_current'] == true ? 'Current semester' : ''),
                    ]),
                    _section('Classes', _addClass, [
                      for (final k in _cls) _row(k['name'], k['department'] ?? ''),
                    ]),
                    _section('Approved teachers', _addTeacher, [
                      for (final t in _tea)
                        _row(
                          t['email'],
                          [
                            if (t['name'] != null) t['name'],
                            if (t['is_admin'] == true) 'admin',
                            t['signed_in_once'] == true
                                ? 'signed in'
                                : 'has not signed in yet',
                          ].join(' · '),
                        ),
                    ]),
                    _section('Subjects', _addSubject, [
                      for (final s in _sub) _row('${s['code']} ${s['name']}', s['kind'] ?? ''),
                    ]),
                  ]),
                ),
    );
  }
}