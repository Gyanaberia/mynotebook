import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_analytics_methods/ga_methods.dart';
import 'package:mynotebook/constants/routes.dart';

enum MenuAction { profile, settings, logout }

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final AnalyticsClass analytics = AnalyticsClass();
  final Widget? appTitle;
  final Widget? leadingIcon;
  final List<Widget>? trailingIcons;
  final bool showMenu;
  final bool automaticallyImplyLeading;
  MyAppBar({
    super.key,
    this.appTitle,
    this.leadingIcon,
    this.trailingIcons,
    this.showMenu = true,
    this.automaticallyImplyLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leadingWidth: 30,
      leading: leadingIcon,
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: appTitle,
      ),
      backgroundColor: Colors.blue,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: [
        if (trailingIcons != null) ...trailingIcons!,
        if (showMenu)
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
                PopupMenuItem(
                    value: MenuAction.profile, child: Text("Profile")),
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
