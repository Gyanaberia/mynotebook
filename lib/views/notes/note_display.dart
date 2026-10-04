import 'dart:async';
import 'dart:developer' as devtools;

import 'package:flutter/material.dart';
import 'package:mynotebook/services/crud/database_model.dart';
import 'package:mynotebook/services/crud/notes_services.dart';
import 'package:mynotebook/widgets/myappbar.dart';

class NoteDisplay extends StatefulWidget {
  const NoteDisplay({super.key, required this.note});
  final DatabaseNotes note;
  @override
  State<NoteDisplay> createState() => _NoteDisplayState();
}

class _NoteDisplayState extends State<NoteDisplay> {
  DatabaseNotes? _note;
  late final NotesServices _notesServices;
  late final TextEditingController _contentController, _titleController;
  final ScrollController _scrollController = ScrollController();
  final _titleFocusNode = FocusNode();
  bool _isEditingTitle = false, _titleNotTouched = true;
  Timer? _titleDebounce, _contentDebounce;

  //Deletes note from db. Called when user goes back to dashboard with empty note
  Future<void> _deleteNotefromDB({bool showMsg = true}) async {
    devtools.log("new note view: deletenotefromDB");

    try {
      await _notesServices.deleteNote(_note!.noteId);
      if (mounted) {
        if (showMsg) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Deleted")),
          );
        }
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("delete Failed")),
        );
      }
    }
  }

  //Update note's title/content in db
  Future<void> _saveNote() async {
    devtools.log("new note view: saveNote");
    if (_note == null) {
      return;
    } else if (_note != null &&
        _titleController.text.isEmpty &&
        _contentController.text.isEmpty) {
      return;
    } else {
      try {
        await _notesServices.updateNote(
            noteId: _note!.noteId,
            title: _titleController.text,
            content: _contentController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Saved")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Saving Failed")),
          );
        }
      }
    }
  }

  bool _isHandlingBack = false;
  Future<void> _handleBackPressed() async {
    devtools.log("new note view: handlebackpressed");
    if (_isHandlingBack) return;
    _isHandlingBack = true;
    try {
      //pending save
      _titleDebounce?.cancel();
      _contentDebounce?.cancel();
      if (_note != null &&
          (_titleController.text.isEmpty && _contentController.text.isEmpty)) {
        await _deleteNotefromDB(showMsg: false);
      } else {
        await _saveNote();
        if (mounted) Navigator.of(context).pop();
      }
    } finally {
      _isHandlingBack = false;
    }
  }

  void _contentControllerListener() {
    _contentDebounce?.cancel();
    _contentDebounce = Timer(const Duration(milliseconds: 500), () {
      final note = _note;
      if (note == null) return;
      devtools.log("titleNotTouched=$_titleNotTouched");
      if (_titleNotTouched) {
        _titleNotTouched = false;
        final firstLine = _contentController.text.split('\n').first.trim();
        _titleController.text =
            firstLine.length > 20 ? firstLine.substring(0, 20) : firstLine;
      }
      _notesServices.updateNote(
          noteId: note.noteId,
          title: _titleController.text,
          content: _contentController.text);
    });
  }

  void _titleControllerListener() {
    _titleDebounce?.cancel();
    _titleDebounce = Timer(const Duration(milliseconds: 500), () {
      final note = _note;
      if (note == null) return;
      devtools.log("Current title is ${_titleController.text}");
      _notesServices.updateNote(
          noteId: note.noteId,
          title: _titleController.text,
          content: _contentController.text);
    });
  }

  void _setupListeners() {
    _titleController.removeListener(_titleControllerListener);
    _titleController.addListener(_titleControllerListener);

    _contentController.removeListener(_contentControllerListener);
    _contentController.addListener(_contentControllerListener);

    _titleFocusNode.removeListener(_onTitleFocusChange);
    _titleFocusNode.addListener(_onTitleFocusChange);
  }

  @override
  void initState() {
    devtools.log("=" * 20);
    devtools.log("NEW NOTE VIEW:INITSTATE");
    super.initState();
    _notesServices = NotesServices();
    _contentController = TextEditingController();
    _titleController = TextEditingController();
    devtools
        .log("Modifying existing note with note title= ${widget.note.title}");
    _note = widget.note;
    _titleController.text = _note!.title;
    _contentController.text = _note!.content;
    _titleNotTouched = false;
    _setupListeners();
  }

  void _onTitleFocusChange() {
    devtools.log(
      "TITLE FOCUS: ${_titleFocusNode.hasFocus}",
    );
    if (_titleFocusNode.hasFocus) {
      _titleNotTouched = false;
    }
    if (_isEditingTitle == _titleFocusNode.hasFocus) return;
    devtools.log("focus listener fired: hasFocus=${_titleFocusNode.hasFocus}");
    if (_isEditingTitle != _titleFocusNode.hasFocus) {
      if (mounted) {
        setState(() {
          _isEditingTitle = _titleFocusNode.hasFocus;
        });
      }
    }
  }

  @override
  void dispose() {
    devtools.log("new note view: dispose");
    _titleDebounce?.cancel();
    _contentDebounce?.cancel();
    _titleController.removeListener(_titleControllerListener);
    _titleController.dispose();
    _contentController.removeListener(_contentControllerListener);
    _contentController.dispose();
    _titleFocusNode.removeListener(_onTitleFocusChange);
    _titleFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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
    devtools.log(
        "build() called, _isEditingTitle=$_isEditingTitle. titlehasFocus=${_titleFocusNode.hasFocus}");
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          devtools.log("clicking back");
          if (didPop) return;
          final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
          if (keyboardVisible) {
            FocusScope.of(context)
                .unfocus(); // stage 1: dismiss keyboard, stay on screen
            return;
          }
          await _handleBackPressed();
        },
        child: noteDisplay());
  }

  Widget noteDisplay() {
    _isEditingTitle = _titleFocusNode.hasFocus;
    return Scaffold(
      appBar: MyAppBar(
        showMenu: false,
        automaticallyImplyLeading: !_isEditingTitle,
        leadingIcon: _isEditingTitle
            ? IconButton(
                onPressed: () {
                  _saveNote();
                  _titleFocusNode.unfocus();
                },
                icon: Icon(Icons.check))
            : null,
        appTitle: TextField(
          onChanged: (value) {
            devtools.log("TITLE ON_CHANGED: '$value'");
          },
          autofillHints: const [],
          controller: _titleController,
          focusNode: _titleFocusNode,
          style:
              TextStyle(color: _isEditingTitle ? Colors.black : Colors.white),
          maxLines: 1,
          // maxLength: 20,
          decoration: InputDecoration(
            hintText: 'Title',
            hintStyle: TextStyle(
              color: _isEditingTitle ? Colors.black54 : Colors.white70,
            ),
            suffixIcon: _isEditingTitle
                ? null
                : const Icon(Icons.edit, color: Colors.white),
            border: InputBorder.none, // no default underline
            filled: _isEditingTitle,
            fillColor: _isEditingTitle ? Colors.white : null,
            counterText:
                '', // suppress the "0/20" counter created due to maxLen
            isDense: true,
          ),
        ),
        trailingIcons: _isEditingTitle
            ? null
            : [
                IconButton(
                    onPressed: _deleteNotefromDB, icon: Icon(Icons.delete))
              ],
      ),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        child: TextField(
          scrollController: _scrollController,
          controller: _contentController,
          keyboardType: TextInputType.multiline,
          maxLines: null,
          decoration: InputDecoration(
            hintText: "Edit here",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
