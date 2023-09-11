import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotebook/constants/routes.dart';

enum MenuAction { profile, settings, logout }

class MyAppBar extends StatelessWidget {
  final String appTitle;
  final AppBar appBar;
  const MyAppBar({super.key, required this.appTitle, required this.appBar});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(appTitle),
      backgroundColor: Colors.blue,
      actions: [
        PopupMenuButton<MenuAction>(
          color: Colors.white,
          onSelected: (value) async {
            switch (value) {
              case MenuAction.logout:
                final shouldLogout = await showLogoutDialog(context);
                if (shouldLogout) {
                  await FirebaseAuth.instance.signOut();
                  // ignore: use_build_context_synchronously
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(loginRoute, (route) => false);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User Logged Out")));
                }
              default:
            }
          },
          itemBuilder: (context) {
            return const [
              PopupMenuItem(value: MenuAction.profile, child: Text("Profile")),
              PopupMenuItem(
                  value: MenuAction.settings, child: Text("Settings")),
              PopupMenuItem(value: MenuAction.logout, child: Text("Log out")),
            ];
          },
        )
      ],
    );
  }

  Future<bool> showLogoutDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Log out"),
          content: const Text("Are you sure you want to log out"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text("Cancel")),
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text("Yes")),
          ],
        );
      },
    ).then((value) => false);
  }
}
