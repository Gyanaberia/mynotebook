import 'package:flutter/material.dart';
import 'package:mynotebook/auth/auth_service.dart';
import 'package:mynotebook/constants/routes.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  AuthService authService = AuthService.firebase();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify Email"),
      ),
      body: Column(
        children: [
          const Text(
              "Please check your mail and verify your email address. If confirmation mail not received, press below"),
          TextButton(
            onPressed: () async {
              authService.sendEmailVerification();
            },
            child: const Text("Send email verification"),
          ),

          TextButton(
            onPressed: () async {
              // BuildContext currentContext = context;
              await authService.logOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(registerRoute, (route) => false);
              }
            },
            child: const Text("Restart"),
          ),
          // TextButton(
          //     onPressed: () async {
          //       final messenger = ScaffoldMessenger.of(context);
          //       await FirebaseAuth.instance.currentUser?.reload();
          //       final user = FirebaseAuth.instance.currentUser;
          //       log(user.toString());
          //       if (user!.emailVerified) {
          //         if (!mounted) return;
          //         Navigator.of(context)
          //             .pushNamedAndRemoveUntil(notesRoute, (route) => false);
          //       } else {
          //         messenger.showSnackBar(
          //             const SnackBar(content: Text("Please Verify email!")));
          //         if (!mounted) return;
          //         Navigator.of(context)
          //             .pushNamedAndRemoveUntil(homeRoute, (route) => false);
          //       }
          //     },
          //     child: const Text("Reload")),
        ],
      ),
    );
  }
}
