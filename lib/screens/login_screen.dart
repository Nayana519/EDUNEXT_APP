import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; 
import 'home_screen.dart';
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

      // ⬇️ UPDATE YOUR NAVIGATION LINKS INSIDE LOGIN_SCREEN WITH THIS PATH ROUTE ⬇️
    if (mounted && userCredential.user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Swap out const HomeScreen() and pass the active role attribute parameters securely
          builder: (context) => const DashboardScreen(role: 'teacher'), // Use 'student' or 'teacher' dynamically
        ),
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

  // 👑 FIXED GOOGLE SIGN-IN METHOD MATCHING V7.0.0+ SINGLETON SURFACE
    // 👑 100% Correct Google Sign-In Flow for google_sign_in 7.2.0+

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleSignIn = GoogleSignIn.instance;

      // Google Sign-In v7 requires initialization
      await googleSignIn.initialize();

      // Start Google sign-in
      final GoogleSignInAccount googleUser =
          await googleSignIn.authenticate();

      // Get Google authentication information
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // Create Firebase credential using Google ID token
      final OAuthCredential credential =
          GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted && userCredential.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Google Sign-In failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        child: SingleChildScrollView( 
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
                        ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                          child: const Text('Log In'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 45)),
                          icon: const Icon(Icons.g_mobiledata, size: 28), 
                          label: const Text('Sign In with Google'),
                        ),
                        const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignupScreen(role: 'student')), 
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
