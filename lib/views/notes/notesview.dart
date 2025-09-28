// import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_analytics_methods/ga_methods.dart';
import 'package:mynotebook/constants/routes.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
import 'package:mynotebook/services/crud/notes_services.dart';
import 'package:mynotebook/widgets/myappbar.dart';
// import 'dart:html' as html;

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  AnalyticsClass analytics = AnalyticsClass();
  final user = AuthService.firebase().currentUser!;
  final NotesServices notesServices = NotesServices();
  @override
  void initState() async {
    super.initState();
    await notesServices.open();
  }

  @override
  void dispose() {
    super.dispose();
    notesServices.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: MyAppBar(
          appTitle: "Notes",
          trailingIcons: [
            IconButton(
                onPressed: () => Navigator.of(context).pushNamed(newNoteRoute),
                icon: Icon(Icons.add))
          ],
        ),
        body: FutureBuilder(
          future: notesServices.getOrCreateUser(
              email: user.email!, username: user.username),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                StreamBuilder(
                    stream: notesServices.allNotes,
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          return Text("bruh");
                        default:
                          return CircularProgressIndicator();
                      }
                    });
              default:
                return CircularProgressIndicator();
            }
            return Text("sth went wrong");
          },
        ));
  }
}
