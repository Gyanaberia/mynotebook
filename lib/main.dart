// import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:flutter/material.dart';
import 'package:mynotebook/constants/routes.dart';
import 'package:mynotebook/views/home_page.dart';
import 'package:mynotebook/views/login_view.dart';
import 'package:mynotebook/views/notes/new_note_view.dart';
import 'package:mynotebook/views/notes/notes_dashboard.dart';
import 'package:mynotebook/views/register_view.dart';
import 'package:mynotebook/views/splash.dart';
import 'package:mynotebook/views/verify_email.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'dart:developer' as devtools show log;

// import 'package:mynotebook/views/verify_email.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); 

  // AuthService.firebase().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  // static FirebaseAnalyticsObserver observer =
  //     FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // navigatorObservers: <NavigatorObserver>[observer],
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
      routes: {
        loginRoute: (context) => const LoginView(),
        registerRoute: (context) => const RegisterView(),
        notesRoute: (context) => const NotesDashboard(),
        homeRoute: (context) => const HomePage(),
        splash: (context) => const SplashScreen(),
        verifyRoute: (context) => const VerifyEmailView(),
        newNoteRoute:(context)=>const NewNoteView(),
      },
    );
  }
}
