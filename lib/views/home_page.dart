import 'package:flutter/material.dart';
// import 'package:mynotebook/constants/routes.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
import 'package:mynotebook/views/login_view.dart';
import 'package:mynotebook/views/notes/notes_dashboard.dart';
import 'package:mynotebook/views/verify_email.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<void> _initFuture;

  //Initialize the AuthService to check the current user status
  @override
  void initState() {
    super.initState();
    _initFuture = AuthService.firebase().initialize();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = AuthService.firebase().currentUser;
            if (user != null) {
              return user.isEmailVerifired? const NotesDashboard() : const VerifyEmailView();
            } else {
              return const LoginView();
            }
          default:
            return const CircularProgressIndicator();
        }
      },
    )

        // Column(
        //   children: [
        //     const Text("Welcome Aboard!!"),
        //     ElevatedButton(
        //         onPressed: () => Navigator.of(context).pushNamed(loginRoute),
        //         child: const Text("Login")),
        //     ElevatedButton(
        //         onPressed: () => Navigator.of(context).pushNamed(registerRoute),
        //         child: const Text("Register")),
        //   ],
        // ),
        );
  }
}
