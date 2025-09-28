import 'package:flutter/material.dart';
import 'package:google_analytics_methods/ga_methods.dart';
import 'package:mynotebook/services/auth/auth_exceptions.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
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
          backgroundColor: Colors.blue,
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
                  AuthService authService = AuthService.firebase();
                  await authService.logIn(userId: email, password: password);
                  const SnackBar(content: Text("User registered"));

                  await authService.sendEmailVerification();

                  analytics.signupEvent('analytics signup');

                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pushNamed(verifyRoute);
                } on WeakPasswordAuthException {
                  const SnackBar(content: Text("Weak Password"));
                } on InvalidEmailAuthException {
                  const SnackBar(content: Text("Invalid Email"));
                } on EmailAlreadyInUseAuthEXception {
                  const SnackBar(content: Text("Email already in use"));
                } on GeneralAuthException {
                  const SnackBar(
                      content: Text("Some error Occured. Please try again."));
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
