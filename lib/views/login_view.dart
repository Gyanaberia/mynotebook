import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import "dart:developer" as devtools show log;

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<LoginView> {
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
          title: const Text("Login"),
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
                      .signInWithEmailAndPassword(
                          email: email, password: password);
                  devtools.log(userCredentials.toString());
                } on FirebaseAuthException catch (e) {
                  if (e.code == "user-not-found") {
                    devtools.log("user not found");
                  } else if (e.code == "wrong-password") {
                    devtools.log("wrong password");
                  }
                }
              },
              child: const Text("Login"),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/register/', (route) => false);
                },
                child: const Text("Don't have an account? Register here!"))
          ],
        ));
  }
}
