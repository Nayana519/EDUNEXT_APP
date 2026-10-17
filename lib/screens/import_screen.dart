import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils.dart';

class ImportScreen extends StatefulWidget {
  final String kind; // 'students' or 'enrollments'
  const ImportScreen({super.key, required this.kind});
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _text = TextEditingController();
  Map<String, dynamic>? _preview;
  Map<String, dynamic>? _result;
  bool _busy = false;
  String? _error;

  bool get _isStudents => widget.kind == 'students';

  String get _example => _isStudents
      ? 'register_number,name,email,class\nCEC001,Asha K,asha@college.edu,S7 CSE-D'
      : 'register_number,class,subject_code\nCEC001,S7 CSE-D,CST412';

  Future<void> _runPreview() async {
    if (_text.text.trim().isEmpty) {
      setState(() => _error = 'Paste the data first.');
      return;
    }
    setState(() { _busy = true; _error = null; _preview = null; _result = null; });
    try {
      final p = await ApiService.importPreview(widget.kind, _text.text);
      if (mounted) setState(() => _preview = p);
    } catch (e) {
      if (mounted) setState(() => _error = apiError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    setState(() { _busy = true; _error = null; });
    try {
      final r = await ApiService.importConfirm(_preview!['batch_id'] as String);
      if (mounted) {
        setState(() { _result = r; _preview = null; _text.clear(); });
      }
    } catch (e) {
      if (mounted) setState(() => _error = apiError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _facts(Map<String, dynamic> m) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final e in m.entries)
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text('${e.key.replaceAll('_', ' ')}: ${e.value}',
              style: const TextStyle(fontSize: 13)),
        ),
    ]);
  }

  Widget _problems(String title, List<dynamic> list, Color color) {
    if (list.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      ),
      for (final e in list.take(30))
        Text(
            'Row ${e['row']}${e['register_number'] != null ? ' (${e['register_number']})' : ''}: ${e['problem']}',
            style: const TextStyle(fontSize: 12.5)),
      if (list.length > 30) Text('...and ${list.length - 30} more'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    final summary = _preview?['summary'] as Map<String, dynamic>?;
    final canApply = ((summary?['to_apply'] ?? 0) as int) > 0;

    return Scaffold(
      appBar: AppBar(
          title: Text(_isStudents ? 'Import class lists' : 'Import subject selections')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text(
          _isStudents
              ? 'Paste the class list. The first line must be the header. Students are added to their class and automatically enrolled in its common subjects. Include the email column: it stops other people from claiming a register number.'
              : 'Paste who takes which subject. The first line must be the header. Use this for electives and for any subject that is not common to the whole class.',
          style: TextStyle(color: c.slate, fontSize: 12.5, height: 1.4),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: c.rule, borderRadius: BorderRadius.circular(8)),
          child: SelectableText(_example,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _text,
          maxLines: 8,
          decoration: const InputDecoration(
              border: OutlineInputBorder(), hintText: 'Paste CSV or Excel rows here'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _busy ? null : _runPreview,
          style: ElevatedButton.styleFrom(
              backgroundColor: c.ink,
              foregroundColor: c.onInk,
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: Text(_busy && _preview == null ? 'Checking...' : 'Preview'),
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
            decoration:
                BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Preview for ${_preview!['semester']}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _facts(summary!),
              _problems('Problems (these rows are skipped)',
                  _preview!['errors'] as List<dynamic>, c.danger),
              _problems('Conflicts (not applied)',
                  _preview!['conflicts'] as List<dynamic>, c.marigold),
            ]),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (_busy || !canApply) ? null : _confirm,
            style: ElevatedButton.styleFrom(
                backgroundColor: c.chalk,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(canApply
                ? 'Confirm import (${summary['to_apply']})'
                : 'Nothing to import'),
          ),
        ],
        if (_result != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration:
                BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Import complete',
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.chalk)),
              const SizedBox(height: 8),
              _facts(_result!),
            ]),
          ),
        ],
      ]),
    );
  }
}