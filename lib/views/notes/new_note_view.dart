import 'dart:async';
import 'dart:developer' as devtools;

import 'package:flutter/material.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
import 'package:mynotebook/services/crud/database_model.dart';
import 'package:mynotebook/services/crud/notes_services.dart';
import 'package:mynotebook/views/notes/note_display.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({
    super.key,
  });
  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  DatabaseNotes? _note;
  late final NotesServices _notesServices;
  Future<void>? _newNote;

  //Create note in db, and returns the note
  Future<DatabaseNotes> _createNoteinDB() async {
    devtools.log("new note view: createNote");
    DatabaseNotes? note;
    try {
      final currentUser = AuthService.firebase().currentUser;
      final owner = await _notesServices.getUser(email: currentUser!.email!);
      note = await _notesServices.createNote(owner: owner);
      return note;
    } catch (e) {
      if (note != null) {
        await _notesServices.deleteNote(note.noteId);
      }
      rethrow;
    }
  }

  //Deletes note from db. Called when user goes back to dashboard with empty note
  // Future<void> _deleteNotefromDB({bool showMsg = true}) async {
  //   devtools.log("new note view: deletenotefromDB");

  //   try {
  //     await _notesServices.deleteNote(_note!.noteId);
  //     if (mounted) {
  //       if (showMsg) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text("Deleted")),
  //         );
  //       }
  //       Navigator.of(context).pop();
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("delete Failed")),
  //       );
  //     }
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _notesServices = NotesServices();
    _newNote = _createNoteinDB();
  }

  //POSSIBLE ACTIONS
  //USER lands on default new note screen. Both title and content in empty mode. Appbar has back and edit icon
  //If user clicks on title, the back button replaced with save button, edit disappears, and it becomes a white block
  //If content is clicked, keyboard appears. If content is typed while title is empty, title also takes in word[20 chars max]
  //If save is clicked:- dismiss keyboard, save with snackbar
  //If keyboard swiped, and swiped again, show a snackbar save everything and go to main screen.
  //If its empty:- dont show anything and go back to screen
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _newNote,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            if (snapshot.hasError) {
              devtools.log("note creation failed: ${snapshot.error}",
                  stackTrace: snapshot.stackTrace);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.of(context).pop(false); // false = failed to open
                }
              });
              return const Scaffold(
                  body: Center(child: Text("Couldn't open note...")));
            }
            _note ??= snapshot.data as DatabaseNotes;
            return NoteDisplay(note: _note!);
          default:
            return CircularProgressIndicator();
        }
      },
    );
  }
}
