import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_analytics_methods/ga_methods.dart';
import 'package:mynotebook/auth/auth_service.dart';
import 'package:mynotebook/constants/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  AnalyticsClass analytics = AnalyticsClass();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    startTime();
  }

  startTime() async {
    var duration = const Duration(seconds: 5);

    return Timer(
      duration,
      () async {
        analytics.logSessionTimeout('Session_timeout');
        await AuthService.firebase().logOut();
        analytics.setUser(null, null);
        if (!mounted) return; //userID is reset
        Navigator.of(context)
            .pushNamedAndRemoveUntil(loginRoute, (route) => false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 20.0)),
            Text(
              "Splash Screen",
              style: TextStyle(
                  fontSize: 20.0, color: Color.fromARGB(255, 0, 0, 0)),
            ),
            Padding(padding: EdgeInsets.only(top: 20.0)),
            CircularProgressIndicator(
              backgroundColor: Color.fromARGB(255, 23, 170, 233),
              strokeWidth: 1,
            )
          ],
        ),
      ),
    );
  }
}
