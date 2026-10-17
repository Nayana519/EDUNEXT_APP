import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils.dart';
import '../widgets/prompt.dart';

class MyClassesScreen extends StatelessWidget {
  const MyClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
      appBar: AppBar(title: const Text('My classes')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.myClasses(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text(apiError(snap.error!)));
          final list = snap.data!;
          if (list.isEmpty) {
            return Center(
                child: Text('You are not a class advisor yet.',
                    style: TextStyle(color: c.slate)));
          }
          return ListView(padding: const EdgeInsets.all(18), children: [
            for (final k in list)
              Container(
                margin: const EdgeInsets.only(bottom: 9),
                decoration: BoxDecoration(
                    color: c.card, borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(k['name'],
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${k['students']} students',
                      style: TextStyle(color: c.slate, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ClassRosterScreen(classGroup: k))),
                ),
              ),
          ]);
        },
      ),
    );
  }
}

class ClassRosterScreen extends StatefulWidget {
  final Map<String, dynamic> classGroup;
  const ClassRosterScreen({super.key, required this.classGroup});
  @override
  State<ClassRosterScreen> createState() => _ClassRosterScreenState();
}

class _ClassRosterScreenState extends State<ClassRosterScreen> {
  late Future<List<dynamic>> _items =
      ApiService.classStudents(widget.classGroup['id']);

  void _reload() {
    setState(() {
      _items = ApiService.classStudents(widget.classGroup['id']);
    });
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _add() async {
    final v = await promptFields(context, 'Add a student',
        ['Register number (e.g. CHN23CS141)', 'Name (only if new)']);
    if (v == null || v[0].isEmpty) return;
    try {
      await ApiService.addToClass(widget.classGroup['id'], v[0], v[1]);
      if (mounted) _reload();
    } catch (e) {
      if (mounted) _toast(apiError(e));
    }
  }

  Future<void> _remove(String reg) async {
    final v = await promptFields(context, 'Remove $reg from the class', ['Reason (required)']);
    if (v == null || !mounted) return;
    if (v[0].length < 3) {
      _toast('Please give a reason.');
      return;
    }
    try {
      await ApiService.removeFromClass(widget.classGroup['id'], reg, v[0]);
      if (mounted) _reload();
    } catch (e) {
      if (mounted) _toast(apiError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.classGroup['name']} students')),
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
                child: Text('No students in this class yet',
                    style: TextStyle(color: c.slate)));
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
                    '${s['register_number']}${s['account_linked'] == true ? '' : ' · not signed up yet'}',
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