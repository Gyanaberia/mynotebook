import 'package:flutter/material.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
import 'package:mynotebook/views/login_view.dart';
import 'package:mynotebook/views/notesview.dart';
import 'package:mynotebook/views/verify_email.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return
        // Scaffold(
        //   appBar: MyAppBar(appTitle: "Welcome Screen", appBar: AppBar()),
        //   body: Column(
        //     children: [
        //       const Text("Welcome Aboard!!"),
        //       ElevatedButton(
        //           onPressed: () => Navigator.of(context)
        //               .pushNamedAndRemoveUntil(loginRoute, (route) => false),
        //           child: const Text("Login")),
        //       ElevatedButton(
        //           onPressed: () => Navigator.of(context)
        //               .pushNamedAndRemoveUntil(registerRoute, (route) => false),
        //           child: const Text("Register")),
        //     ],
        //   ),
        // );

        FutureBuilder(
      future: AuthService.firebase().initialize(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = AuthService.firebase().currentUser;
            if (user != null) {
              if (user.isEmailVerifired) {
                return const NotesView();
              } else {
                // devtools.log("passed through main.dart");

                return const VerifyEmailView();
              }
            } else {
              return const LoginView();
            }
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}
