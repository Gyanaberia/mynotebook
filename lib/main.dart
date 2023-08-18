import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:mynotebook/firebase_options.dart';
import 'package:mynotebook/views/login_view.dart';
import 'package:mynotebook/views/register_view.dart';
import 'dart:developer' as devtools show log;

import 'package:mynotebook/views/verify_email.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // what does it do?
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const HomePage(),
    routes: {
      '/login/': (context) => const LoginView(),
      '/register/': (context) => const RegisterView()
    },
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              if (user.emailVerified) {
                devtools.log("User is verified");
              } else {
                return const VerifyEmailView();
              }
            } else {
              return const LoginView();
            }
            return const Text("DOne");
          // devtools.log(FirebaseAuth.instance.currentUser.toString());
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}
