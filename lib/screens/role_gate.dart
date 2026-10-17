import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'choose_role_screen.dart';
import 'main_shell.dart';
import 'verify_email_screen.dart';

class RoleGate extends StatefulWidget {
  const RoleGate({super.key});
  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  Map<String, dynamic>? _user;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final me = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _user = me;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Something went wrong. Check the server and try again.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                },
                child: const Text('Try again'),
              ),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Sign out'),
              ),
            ]),
          ),
        ),
      );
    }

    final user = _user!;
    if (user['role'] == null) {
      final fb = FirebaseAuth.instance.currentUser;
      if (fb != null && !fb.emailVerified) {
        return VerifyEmailScreen(onVerified: () => setState(() {}));
      }
      return ChooseRoleScreen(onDone: (me) => setState(() => _user = me));
    }
    return MainShell(me: user);
  }
}