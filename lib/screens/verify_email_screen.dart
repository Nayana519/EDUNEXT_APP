import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  final VoidCallback onVerified;
  const VerifyEmailScreen({super.key, required this.onVerified});
  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _resend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await user.sendEmailVerification();
      if (mounted) {
        setState(() => _message =
            'Email sent to ${user.email}. Check your inbox and spam folder.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _message = e.message ?? 'Could not send the email.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.emailVerified) {
        await user.getIdToken(true); // a new token that says "verified"
        if (mounted) widget.onVerified();
        return;
      }
      if (mounted) {
        setState(() => _message =
            'Not verified yet. Open the link in the email, then tap this button again.');
      }
    } catch (e) {
      if (mounted) setState(() => _message = 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.mark_email_unread_outlined, size: 56, color: c.ink),
            const SizedBox(height: 16),
            const Text('Verify your email',
                style: TextStyle(
                    fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'We sent a link to $email. Open it, then come back and tap the button below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: c.slate, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _check,
                style: ElevatedButton.styleFrom(
                    backgroundColor: c.ink,
                    foregroundColor: c.onInk,
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(_busy ? 'Checking...' : "I've verified my email"),
              ),
            ),
            TextButton(
                onPressed: _busy ? null : _resend,
                child: const Text('Send the email again')),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_message!,
                    textAlign: TextAlign.center, style: TextStyle(color: c.slate)),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text('Use a different account'),
            ),
          ]),
        ),
      ),
    );
  }
}