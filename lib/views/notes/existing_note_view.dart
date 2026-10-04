import 'package:flutter/material.dart';
import 'package:mynotebook/services/crud/database_model.dart';
import 'package:mynotebook/views/notes/note_display.dart';

class ExistingNoteView extends StatelessWidget {
  const ExistingNoteView({super.key, required this.note});
  final DatabaseNotes note;
  @override
  Widget build(BuildContext context) {
    return NoteDisplay(note: note);
  }
}