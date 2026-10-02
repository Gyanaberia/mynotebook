import 'package:flutter/material.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
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
                    .pushNamedAndRemoveUntil(loginRoute, (route) => false);
              }
            },
            child: const Text("Restart"),
          ),
        ],
      ),
    );
  }
}
