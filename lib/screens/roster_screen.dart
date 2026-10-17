import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils.dart';
import '../widgets/prompt.dart';
import 'audit_screen.dart';

class RosterScreen extends StatefulWidget {
  final Map<String, dynamic> subject;
  const RosterScreen({super.key, required this.subject});
  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  late Future<List<dynamic>> _items = ApiService.getRoster(widget.subject['id']);

  void _reload() {
  setState(() {
    _items = ApiService.getRoster(widget.subject['id']);
  });
}

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _add() async {
    final v = await promptFields(
        context, 'Add a student', ['Register number', 'Reason (optional)']);
    if (v == null || v[0].isEmpty) return;
    try {
      await ApiService.addToRoster(
          widget.subject['id'], v[0].toUpperCase(), v[1].isEmpty ? null : v[1]);
      _reload();
    } catch (e) {
      if (mounted) _toast(apiError(e));
    }
  }

  Future<void> _remove(String reg) async {
    final v = await promptFields(context, 'Remove $reg', ['Reason (required)']);
    if (v == null || !mounted) return;
    if (v[0].length < 3) {
      _toast('Please give a reason.');
      return;
    }
    try {
      await ApiService.removeFromRoster(widget.subject['id'], reg, v[0]);
      _reload();
    } catch (e) {
      if (mounted) _toast(apiError(e));
    }
  }

  String _source(String s) =>
      {'common_auto': 'automatic', 'imported': 'imported', 'manual': 'added manually'}[s] ?? s;

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
       appBar: AppBar(
        title: Text('${widget.subject['code']} students'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => AuditScreen(subject: widget.subject))),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.chalk,
        foregroundColor: Colors.white,
        onPressed: _add,
        icon: const Icon(Icons.person_add),
        label: const Text('Add student'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _items,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text(apiError(snap.error!)));
          final list = snap.data!;
          if (list.isEmpty) {
            return Center(
                child: Text('No students enrolled yet', style: TextStyle(color: c.slate)));
          }
          return ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 90), children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('${list.length} students',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            for (final s in list)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: c.card, borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(s['name'],
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${s['register_number']} · ${_source(s['source'])}${s['account_linked'] == true ? '' : ' · not signed up yet'}',
                    style: TextStyle(fontSize: 11.5, color: c.slate),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: () => _remove(s['register_number']),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }
}