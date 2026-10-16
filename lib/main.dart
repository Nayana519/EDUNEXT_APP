import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ⬇️ ADDED THIS IMPORT FOR AUTH
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/role_gate.dart';
import 'screens/login_screen.dart';

void main() async {
  // Flutter needs this line before doing anything async in main()
  WidgetsFlutterBinding.ensureInitialized();

  // Connects the app to your Firebase project
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ⬇️ SAFELY MOVED INSIDE THE MAIN SYSTEM BLOCK ⬇️
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      print('User is currently signed out!');
    } else {
      print('User is signed in! Redirect to Home Screen.');
    }
  });

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
@override
Widget build(BuildContext context) {
  return ValueListenableBuilder<String>(
    valueListenable: themeNotifier,
    builder: (context, themeKey, _) {
      return MaterialApp(
        title: 'EduNex',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(themeKey),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Logged in -> RoleGate (opens the app, or asks the role only once)
            if (snapshot.hasData && snapshot.data != null) {
              return RoleGate(key: ValueKey(snapshot.data!.uid));
            }

            // Logged out -> login screen
            return const LoginScreen();
          },
        ),
      );
    },
  );
}
}
