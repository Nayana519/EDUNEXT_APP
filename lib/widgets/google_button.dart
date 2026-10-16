import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class GoogleButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  const GoogleButton({super.key, this.onSuccess});
  @override
  State<GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<GoogleButton> {
  bool _busy = false;

  Future<void> _go() async {
    setState(() => _busy = true);
    try {
      await signInWithGoogle();
      if (mounted) widget.onSuccess?.call();
    } catch (e) {
      final text = e.toString();
      if (!text.toLowerCase().contains('cancel') && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $text')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : _go,
        icon: const Icon(Icons.g_mobiledata, size: 30),
        label: Text(_busy ? 'Signing in...' : 'Continue with Google'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}