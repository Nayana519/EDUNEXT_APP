import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key});
  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _subjectId;
  bool _busy = false;
  late final Future<List<dynamic>> _subjects = ApiService.getSubjects();

  Future<void> _post() async {
    if (_title.text.trim().isEmpty || _subjectId == null) return;
    setState(() => _busy = true);
    try {
      await ApiService.createPost(
          subjectId: _subjectId, title: _title.text.trim(), body: _body.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New announcement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          FutureBuilder<List<dynamic>>(
            future: _subjects,
            builder: (context, snap) => DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Post to'),
              items: [
                for (final s in snap.data ?? [])
                  DropdownMenuItem(value: s['id'] as String, child: Text('${s['code']} - ${s['name']}')),
              ],
              onChanged: (v) => setState(() => _subjectId = v),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(
              controller: _body,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _post,
              child: Text(_busy ? 'Posting...' : 'Post announcement'),
            ),
          ),
        ]),
      ),
    );
  }
}