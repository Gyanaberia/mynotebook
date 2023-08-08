import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import "dart:developer" as devtools show log;
import '../firebase_options.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
      body: FutureBuilder(
        future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              return Column(
                children: [
                  TextField(
                    decoration:
                        const InputDecoration(hintText: "Enter your email"),
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
                        // print(userCredentials);
                        const SnackBar(content: Text("User registered"));
                        // ignore: use_build_context_synchronously
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login/', (route) => false);
                      } on FirebaseAuthException catch (e) {
                        if (e.code == "weak-password") {
                          devtools.log("Weak password");
                        } else if (e.code == "invalid-email") {
                          devtools.log("Invalid email");
                        } else if (e.code == "email-already-in-use") {
                          devtools.log("Email already in use");
                        }
                      }
                    },
                    child: const Text("Register"),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login/', (route) => false);
                      },
                      child: const Text("Already have an account? Login here!"))
                ],
              );
            default:
              return const Text("Loading...");
          }
        },
      ),
    );
  }
}
