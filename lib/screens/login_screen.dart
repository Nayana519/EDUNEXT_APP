import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // 1. Added import for Google Sign-In
import 'home_screen.dart';
import 'signup_screen.dart'; // Make sure this file exists in your project

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

  // 2. AUTO-REDIRECT GUARD: Checks if a user session is active on layout load
  @override
  void initState() {
    super.initState();
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      });
    }
  }

  // Handle Standard Email & Password Login
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final token = await credential.user?.getIdToken();
      debugPrint('Logged in! Token: $token'); 

      // TODO: send `token` to your FastAPI backend to fetch this user's profile

      if (mounted && credential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }

    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Login failed. Check your email and password.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 3. GOOGLE SIGN-IN HANDLER: Triggered when the user clicks the Google button
  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Trigger the Google interactive overlay popup window
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // User cancelled the popup overlay window context
      }

      // Obtain authorization authentication tokens from the request payload
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a clean credential packet for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign into Firebase with the verified Google tokens
      final UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithCredential(credential);
      
      final token = await userCredential.user?.getIdToken();
      debugPrint('Logged in via Google! Token: $token');

      // TODO: send `token` to your FastAPI backend down to Supabase

      if (mounted && userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Google Sign-In failed.';
      });
    } finally {
      setState(() => _isLoading = false);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView( // Wrapped in scroll view to prevent keyboard overflow layout breaks
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              _isLoading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        // Standard Email Login Button
                        ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                          child: const Text('Log In'),
                        ),
                        const SizedBox(height: 12),
                        // 4. NEW GOOGLE LOG IN CLICK ELEMENT
                        OutlinedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                          icon: const Icon(Icons.g_mobiledata, size: 28), // You can swap this for an image asset if preferred
                          label: const Text('Sign In with Google'),
                        ),
                        const SizedBox(height: 24),
                        // Navigation toggle link to redirect to registration
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupScreen()),
                            );
                          },
                          child: const Text("Don't have an account? Sign Up"),
                        )
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
