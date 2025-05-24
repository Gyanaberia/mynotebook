// import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_analytics_methods/ga_methods.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
import 'package:mynotebook/constants/routes.dart';
import 'package:mynotebook/widgets/myappbar.dart';
// import 'dart:html' as html;
import 'package:url_launcher/url_launcher.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  AnalyticsClass analytics = AnalyticsClass();
  final user = AuthService.firebase().currentUser;
  final linkString = 'https://www.youtube.com';
  // @override
  // Future<void> initState() async {
  //   await FirebaseAnalytics.instance.setUserId(id: '123456');
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appTitle: "Notes", appBar: AppBar()),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(user?.email ?? "Gyana "),
            OutlinedButton(
                onPressed: () {
                  analytics
                      .logCustomEvent("Outbound Link", {'link': linkString});
                  // FirebaseAnalytics.instance.logEvent(
                  //     name: "Outbound Link", parameters: {'link': linkString});
                  launchUrl(Uri.parse('https://www.youtube.com'));
                },
                child: const Text("Go to Site 1")),
            OutlinedButton(
                onPressed: () {
                  analytics.logCustomEvent(
                      "Outbound Link", {'link': 'https://www.medium.com'});
                  // FirebaseAnalytics.instance.logEvent(
                  //     name: "Outbound Link", parameters: {'link': linkString});
                  launchUrl(Uri.parse('https://www.medium.com'));
                },
                child: const Text("Go to Site 2")),
            ElevatedButton(
                onPressed: () {
                  analytics
                      .logCustomEvent('form_1', {'step': '1)Account Info'});
                  // FirebaseAnalytics.instance.logEvent(
                  //     name: "Form", parameters: {'step': '1)Account Info'});
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(formsRoute, (route) => false);
                },
                child: const Text("Forms")),
            ElevatedButton(
              onPressed: () {
                analytics.logCustomEvent('form_2-start', null);
                // FirebaseAnalytics.instance.logEvent(
                //     name: 'newform', parameters: {'newform_step': 'step1'});
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(newForm, (route) => false);
              },
              child: const Text("New Form"),
            ),
            ElevatedButton(
              onPressed: () {
                // analytics.logCustomEvent('form_2-step1', null);

                Navigator.of(context)
                    .pushNamedAndRemoveUntil(splash, (route) => false);
              },
              child: const Text("Session Timeout"),
            ),
          ],
        ),
      ),
    );
  }
}
