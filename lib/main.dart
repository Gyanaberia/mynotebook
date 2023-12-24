// import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:flutter/material.dart';
import 'package:mynotebook/constants/routes.dart';
import 'package:mynotebook/views/home_page.dart';
import 'package:mynotebook/views/new_form.dart';
import 'package:mynotebook/views/form_page.dart';
import 'package:mynotebook/views/login_view.dart';
import 'package:mynotebook/views/notesview.dart';
import 'package:mynotebook/views/register_view.dart';
import 'package:mynotebook/views/splash.dart';
import 'package:mynotebook/views/verify_email.dart';
// import 'dart:developer' as devtools show log;

// import 'package:mynotebook/views/verify_email.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // AuthService.firebase().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
        notesRoute: (context) => const NotesView(),
        formsRoute: (context) => const FormPage(),
        homeRoute: (context) => const HomePage(),
        newForm: (context) => const NewCustomForm(),
        splash: (context) => const SplashScreen(),
        verifyRoute: (context) => const VerifyEmailView(),
      },
    );
  }
}
