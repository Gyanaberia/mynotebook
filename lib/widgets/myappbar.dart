import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_analytics_methods/ga_methods.dart';
import 'package:mynotebook/constants/routes.dart';

enum MenuAction { profile, settings, logout }

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AnalyticsClass analytics = AnalyticsClass();
  final String appTitle;
  final AppBar appBar;
  MyAppBar({super.key, required this.appTitle, required this.appBar});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(appTitle),
      backgroundColor: Colors.blue,
      actions: [
        IconButton(
            onPressed: () {
              final route = ModalRoute.of(context);
              log(route?.settings.name ?? "No idea");
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(route?.settings.name ?? "No idea")));

              analytics.logCustomEvent('home_screen',
                  {'initial_page': route?.settings.name ?? "No idea"});
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(notesRoute, (route) => false);
            },
            icon: const Icon(Icons.home)),
        PopupMenuButton<MenuAction>(
          color: Colors.white,
          onSelected: (value) async {
            switch (value) {
              case MenuAction.logout:
                final shouldLogout = await showLogoutDialog(context);
                log(shouldLogout.toString());
                if (shouldLogout) {
                  final user = FirebaseAuth.instance.currentUser;
                  analytics.logSessionTimeout('custom_logout_event',
                      {'user_email_id': user?.email ?? "not known"});
                  await FirebaseAuth.instance.signOut();
                  analytics.setUser(null, null); //userID is reset

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
    ).then((value) => value ?? false);
  }

  @override
  Size get preferredSize => const Size.fromHeight(50);
}
