import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ⬇️ ADDED THIS IMPORT FOR AUTH
import 'firebase_options.dart';
import 'screens/role_select_screen.dart';

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
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduNex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // ⬇️ UPDATED THIS TO AUTOMATICALLY SWITCH PAGES ⬇️
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // If Firebase is still loading the login status, show a spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // If the user is logged in, send them to the Home/Role Screen
          if (snapshot.hasData && snapshot.data != null) {
            // Replace 'YourHomeScreen()' with your actual home screen widget name
            return const RoleSelectScreen(); 
          }
          
          // If they are logged out, show the Login/SignUp screen layout
          // Replace 'LoginScreen()' with your actual login screen widget name
          return const RoleSelectScreen(); 
        },
      ),
    );
  }
}
