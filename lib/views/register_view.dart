import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_analytics_methods/ga_methods.dart';
import "dart:developer" as devtools show log;

import 'package:mynotebook/constants/routes.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  AnalyticsClass analytics = AnalyticsClass();

  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _cpassword;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    _cpassword = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _cpassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Register"),
        ),
        body: Column(
          children: [
            TextField(
              decoration: const InputDecoration(hintText: "Enter your email"),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              controller: _email,
            ),
            TextField(
              decoration: const InputDecoration(hintText: "Password"),
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              controller: _password,
            ),
            TextButton(
              onPressed: () async {
                final email = _email.text;
                final password = _password.text;

                try {
                  final userCredentials = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                          email: email, password: password);
                  devtools.log(userCredentials.toString());
                  const SnackBar(content: Text("User registered"));

                  analytics.signupEvent('analytics signup');

                  // FirebaseAnalytics.instance
                  //     .logSignUp(signUpMethod: "Custom Signup");
                  // ignore: use_build_context_synchronously
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(loginRoute, (route) => false);
                } on FirebaseAuthException catch (e) {
                  print(e.toString());
                  print(e.code);
                  if (e.code == "auth/weak-password") {
                    devtools.log("Weak password");
                    const SnackBar(content: Text("Weak Password"));
                  } else if (e.code == "auth/invalid-email") {
                    devtools.log("Invalid email");
                    const SnackBar(content: Text("Invalid Email"));
                  } else if (e.code == "auth/email-already-in-use") {
                    devtools.log("Email already in use");
                    const SnackBar(content: Text("Email already in user"));
                  } else {
                    const SnackBar(
                        content: Text("Some error occured. Try Again!!"));
                  }
                }
              },
              child: const Text("Register"),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(loginRoute, (route) => false);
                },
                child: const Text("Already have an account? Login here!"))
          ],
        ));
  }
}
