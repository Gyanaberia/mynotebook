import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:mynotebook/constants/routes.dart';
import 'package:mynotebook/firebase_options.dart';
import 'package:mynotebook/views/new_form.dart';
import 'package:mynotebook/views/form_page.dart';
import 'package:mynotebook/views/login_view.dart';
import 'package:mynotebook/views/notesview.dart';
import 'package:mynotebook/views/register_view.dart';
import 'package:mynotebook/views/splash.dart';
// import 'dart:developer' as devtools show log;

// import 'package:mynotebook/views/verify_email.dart';
import 'package:mynotebook/widgets/myappbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      navigatorObservers: <NavigatorObserver>[observer],
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
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appTitle: "Welcome Screen", appBar: AppBar()),
      body: Column(
        children: [
          Text("Welcome Aboard!!"),
          ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(loginRoute, (route) => false),
              child: Text("Login")),
          ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pushNamedAndRemoveUntil(registerRoute, (route) => false),
              child: Text("Register")),
        ],
      ),
    );

    // return FutureBuilder(
    //   future: Firebase.initializeApp(
    //     options: DefaultFirebaseOptions.currentPlatform,
    //   ),
    //   builder: (context, snapshot) {
    //     switch (snapshot.connectionState) {
    //       case ConnectionState.done:
    //         final user = FirebaseAuth.instance.currentUser;
    //         if (user != null) {
    //           if (user.emailVerified) {
    //             Navigator.of(context)
    //                 .pushNamedAndRemoveUntil(notesRoute, (route) => false);
    //             return const NotesView();
    //           } else {
    //             devtools.log("passed through main.dart");

    //             return const VerifyEmailView();
    //           }
    //         } else {
    //           return const LoginView();
    //         }
    //       default:
    //         return const CircularProgressIndicator();
    //     }
    //   },
    // );
  }
}
