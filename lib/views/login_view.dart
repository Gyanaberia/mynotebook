import 'package:flutter/material.dart';
import 'package:google_analytics_methods/ga_methods.dart';
import 'package:mynotebook/auth/auth_exceptions.dart';
import 'package:mynotebook/auth/auth_service.dart';
import 'package:mynotebook/constants/routes.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _cpassword;
  AnalyticsClass analytics = AnalyticsClass();
  AuthService authService = AuthService.firebase();
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
                final message = ScaffoldMessenger.of(context);
                try {
                  if (email == '' || password == '') {
                    message.showSnackBar(const SnackBar(
                        content: Text("Empty email or password field!")));
                  }
                  //PERFORM LOGIN AUTHENTICATION

                  authService.logIn(userId: email, password: password);

                  //SET USER PROPERTIES
                  if (email == 'tester@gmail.com') {
                    analytics.setUser(email, 'user');
                  } else if (email == "tester3@gmail.com") {
                    analytics.setUser(email, "manager");
                  } else if (email == 'tester2@gmail.com') {
                    analytics.setUser(email, 'manager');
                  } else {
                    analytics.setUser(email, 'user');
                  }

                  //LOG LOGIN EVENT
                  analytics.logCustomEvent(
                      'login_event', {'method': "firebase_login"});

                  analytics.loginEvent('new_custom_login');

                  if (!mounted) return;
                  final user = authService.currentUser;
                  if (user?.isEmailVerifired ?? false) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(notesRoute, (route) => false);
                  } else {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(verifyRoute, (route) => false);
                  }
                  //NAVIGATE TO DASHBOARD
                } on InvalidEmailAuthException {
                  message.showSnackBar(const SnackBar(
                      content: Text("Not a valid user or password")));
                } on WrongPasswordAuthEXception {
                  message.showSnackBar(
                      const SnackBar(content: Text("Password is incorrect!!")));
                } on UserNotFoundAuthException {
                  message.showSnackBar(
                      const SnackBar(content: Text("There is no such user!!")));
                } on GeneralAuthException {
                  message.showSnackBar(const SnackBar(
                      content: Text("Some error occured. Please try again")));
                }
              },
              child: const Text("Login"),
            ),
            TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(registerRoute, (route) => false);
                },
                child: const Text("Don't have an account? Register here!"))
          ],
        ));
  }
}
