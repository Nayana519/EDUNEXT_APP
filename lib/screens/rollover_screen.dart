import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils.dart';

class RolloverScreen extends StatefulWidget {
  const RolloverScreen({super.key});
  @override
  State<RolloverScreen> createState() => _RolloverScreenState();
}

class _RolloverScreenState extends State<RolloverScreen> {
  final _year = TextEditingController();
  final _name = TextEditingController();
  Map<String, dynamic>? _preview;
  Map<String, dynamic>? _done;
  bool _busy = false;
  String? _error;

  Future<void> _run({required bool confirm}) async {
    if (_year.text.trim().isEmpty || _name.text.trim().isEmpty) {
      setState(() => _error = 'Enter the academic year and the new semester name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ApiService.rollover(_year.text.trim(), _name.text.trim(),
          confirm: confirm);
      if (!mounted) return;
      setState(() {
        if (confirm) {
          _done = r;
          _preview = null;
        } else {
          _preview = r;
          _done = null;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = apiError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    final classes = (_preview?['classes'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Semester rollover')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text(
          'Starts a new semester and carries your classes and students into it. Old semesters, enrollments and notes are kept.',
          style: TextStyle(color: c.slate, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _year,
          decoration: const InputDecoration(
              labelText: 'New academic year (e.g. 2027-28)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
              labelText: 'New semester name (e.g. S8)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _busy ? null : () => _run(confirm: false),
          style: ElevatedButton.styleFrom(
              backgroundColor: c.ink,
              foregroundColor: c.onInk,
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Preview'),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_error!, style: TextStyle(color: c.danger)),
          ),
        if (_preview != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_preview!['old_semester']}  ->  ${_preview!['new_semester']}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (classes.isEmpty) const Text('No classes to carry over.'),
              for (final k in classes)
                Text('${k['from']}  ->  ${k['to']}  (${k['students']} students)'),
              const SizedBox(height: 8),
              Text(_preview!['note'],
                  style: TextStyle(fontSize: 12, color: c.slate, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _busy ? null : () => _run(confirm: true),
            style: ElevatedButton.styleFrom(
                backgroundColor: c.chalk,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Confirm rollover'),
          ),
        ],
        if (_done != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12)),
            child: Text(
              'Done. ${_done!['semester']} is now the current semester. ${_done!['classes_created']} classes created, ${_done!['students_carried']} students carried over. Next: add the new semester\'s subjects in Academic setup.',
              style: TextStyle(color: c.chalk, height: 1.4),
            ),
          ),
        ],
      ]),
    );
  }
}