import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/google_button.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Enter your email and password.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      // No navigation here: main.dart switches screens by itself.
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage =
            e.message ?? 'Login failed. Check your email and password.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Type your email above first.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('If an account exists, a reset link was sent to $email')));
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message ?? 'Could not send the email.');
    }
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.edu;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                    color: c.ink, borderRadius: BorderRadius.circular(18)),
                child: Icon(Icons.school, color: c.onInk, size: 30),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _forgotPassword, child: const Text('Forgot password?')),
              const Text('EduNex',
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 24,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('One place for class updates, notes, and assignments.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.slate, fontSize: 13)),
              const SizedBox(height: 28),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10))),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.danger)),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.ink,
                    foregroundColor: c.onInk,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Log In'),
                ),
              ),
              const SizedBox(height: 14),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('or')),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 14),
              const GoogleButton(),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SignupScreen())),
                child: const Text("Don't have an account? Sign Up"),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}