import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChooseRoleScreen extends StatefulWidget {
  final void Function(Map<String, dynamic> me) onDone;
  const ChooseRoleScreen({super.key, required this.onDone});
  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  bool _busy = false;
  final _reg = TextEditingController();
  String? _error;
  static Future<Map<String, dynamic>> register(String role, {String? registerNumber}) async =>
    (await _dio.post('/auth/register', data: {
      'role': role,
      if (registerNumber != null && registerNumber.isNotEmpty)
        'register_number': registerNumber,
    })).data;
  Future<void> _choose(String role) async {
  if (role == 'student' && _reg.text.trim().isEmpty) {
    setState(() => _error = 'Enter your register number first.');
    return;
  }
  setState(() { _busy = true; _error = null; });
  try {
    final me = await ApiService.register(role, registerNumber: _reg.text.trim());
      if (mounted) widget.onDone(me);
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? data['detail']?.toString() : null;
      final slow = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout;
      if (mounted) {
        setState(() => _error = msg ??
            (slow
                ? 'The server is taking too long. Check that the backend is running.'
                : 'Could not reach the server.'));
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  

  Widget _card(String role, String title, String sub, IconData icon) {
    final c = context.edu;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _busy ? null : () => _choose(role),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(
                  backgroundColor: c.ink,
                  child: Icon(icon, color: c.onInk, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(sub,
                          style: TextStyle(fontSize: 11.5, color: c.slate)),
                    ]),
              ),
              Icon(Icons.chevron_right, color: c.slate),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Welcome to EduNex',
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 24,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
                controller: _reg,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Register number (students)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            _card('student', "I'm a student",
                'Class feed, materials, assignments', Icons.school),
            _card('teacher', "I'm a teacher",
                'Needs approval from your college', Icons.groups),
            if (_busy)
              const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.danger)),
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text('Sign out'),
            ),
          ]),
        ),
      ),
    );
  }
}