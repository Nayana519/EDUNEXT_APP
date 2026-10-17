import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils.dart';

class _Target {
  final String kind; // 'subject' or 'class'
  final String id;
  final String label;
  const _Target(this.kind, this.id, this.label);
}

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});
  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  List<_Target> _targets = [];
  _Target? _selected;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final t = await ApiService.getPostTargets();
      final list = <_Target>[
        for (final c in t['classes'] as List)
          _Target('class', c['id'], 'Whole class: ${c['name']}'),
        for (final s in t['subjects'] as List)
          _Target('subject', s['id'], '${s['code']} - ${s['name']}'),
      ];
      if (!mounted) return;
      setState(() {
        _targets = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = apiError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _post() async {
    final target = _selected;
    if (target == null || _title.text.trim().isEmpty) {
      setState(() => _error = 'Choose who to post to and add a title.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ApiService.createPost(
        subjectId: target.kind == 'subject' ? target.id : null,
        classId: target.kind == 'class' ? target.id : null,
        title: _title.text.trim(),
        body: _body.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = apiError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
      appBar: AppBar(title: const Text('New announcement')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(18), children: [
              DropdownButtonFormField<_Target>(
                initialValue: _selected,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Post to', border: OutlineInputBorder()),
                items: [
                  for (final t in _targets)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (v) => setState(() => _selected = v),
              ),
              if (_targets.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('You have no subjects or classes yet.',
                      style: TextStyle(color: c.slate)),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                maxLines: 5,
                decoration: const InputDecoration(
                    labelText: 'Message', border: OutlineInputBorder()),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: TextStyle(color: c.danger)),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _busy ? null : _post,
                style: ElevatedButton.styleFrom(
                    backgroundColor: c.ink,
                    foregroundColor: c.onInk,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(_busy ? 'Posting...' : 'Post announcement'),
              ),
            ]),
    );
  }
}