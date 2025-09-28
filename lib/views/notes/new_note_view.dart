import 'package:flutter/material.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
import 'package:mynotebook/services/crud/database_model.dart';
import 'package:mynotebook/services/crud/notes_services.dart';
import 'package:mynotebook/widgets/myappbar.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  DatabaseNotes? _note;
  late final NotesServices _notesServices;
  late final TextEditingController _contentController;
  late final TextEditingController _titleController;

  Future<DatabaseNotes> _createNote() async {
    var note = _note;
    if (note != null) {
      return note;
    } else {
      final curretUser = AuthService.firebase().currentUser;
      final owner = await _notesServices.fetchUser(email: curretUser!.email!);
      note = await _notesServices.createNote(owner: owner);
      return note;
    }
  }

  void _deleteNote() {
    if (_note != null &&
        _titleController.text.isEmpty &&
        _contentController.text.isEmpty) {
      _notesServices.deleteNote(_note!.noteId);
    }
  }

  void _saveNote() {
    if (_note != null &&
        (_titleController.text.isNotEmpty ||
            _contentController.text.isNotEmpty)) {
      _notesServices.updateNote(
          noteId: _note!.noteId,
          title: _titleController.text,
          content: _contentController.text);
    }
  }

  void _contentControllerListener() {
    final note = _note;
    if (note == null) return;
    _notesServices.updateNote(
        noteId: note.noteId, content: _contentController.text);
  }

  void _titleControllerListener() {
    final note = _note;
    if (note == null) return;
    _notesServices.updateNote(
        noteId: note.noteId, title: _titleController.text);
  }

  void _setupListeners() {
    _titleController.removeListener(_titleControllerListener);
    _titleController.addListener(_titleControllerListener);

    _contentController.removeListener(_contentControllerListener);
    _contentController.addListener(_contentControllerListener);
  }

  @override
  void initState() {
    super.initState();
    _notesServices = NotesServices();
    _contentController = TextEditingController();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _deleteNote();
    _saveNote();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _createNote(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            _note = snapshot.data as DatabaseNotes;
            _titleController.text = _note!.title;
            _setupListeners();

            return Scaffold(
              appBar: MyAppBar(
                appTitle: "",
                trailingIcons: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextField(
                        controller: _titleController,
                        maxLines: 1,
                        maxLength: 20,
                        decoration:
                            InputDecoration(suffixIcon: Icon(Icons.edit)),
                      ),
                      SizedBox()
                    ],
                  ),
                ],
              ),
              body: TextField(
                controller: _contentController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration(hintText: "Edit here"),
              ),
            );
          default:
            return CircularProgressIndicator();
        }
      },
    );
  }
}
