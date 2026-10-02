// import 'package:flutter/gestures.dart';
import 'dart:developer' as devtools;

import 'package:flutter/material.dart';
import 'package:google_analytics_methods/ga_methods.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
import 'package:mynotebook/services/crud/database_model.dart';
import 'package:mynotebook/services/crud/notes_services.dart';
import 'package:mynotebook/views/notes/existing_note_view.dart';
import 'package:mynotebook/views/notes/new_note_view.dart';
import 'package:mynotebook/widgets/myappbar.dart';
// import 'dart:html' as html;

class NotesDashboard extends StatefulWidget {
  const NotesDashboard({super.key});

  @override
  State<NotesDashboard> createState() => _NotesDashboardState();
}

class _NotesDashboardState extends State<NotesDashboard> {
  AnalyticsClass analytics = AnalyticsClass();
  final user = AuthService.firebase().currentUser!;
  final NotesServices notesServices = NotesServices();
  late final Future<void> _initFuture;
  final Set<int> _selectedNoteIds = {};
  bool get _isSelecting => _selectedNoteIds.isNotEmpty;

  final Set<int> _allNoteIds = {};
  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    devtools.log("=" * 20);
    devtools.log("NOTE VIEW:INITSTATE");
    try {
      await notesServices.open();

      final notesUser = await notesServices.getOrCreateUser(
        email: user.email!,
        username: user.username,
      );
      await notesServices.setCurrentUser(notesUser);
      await pruneEmptyNotes(notesUser.userId);
    } catch (e, stackTrace) {
      devtools.log(
        "Dashboard initialization FAILED",
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> pruneEmptyNotes(int userId) async {
    final noteList = await notesServices.getAllNotesOfUser(userId);
    for (final n in noteList) {
      if (n.title.trim().isEmpty && n.content.trim().isEmpty) {
        await notesServices.deleteNote(n.noteId);
      }
    }
  }

  void _toggleSelection(int noteId) {
    devtools.log("toggling $noteId");
    setState(() {
      devtools.log("is present ${_selectedNoteIds.contains(noteId)}");
      if (_selectedNoteIds.contains(noteId)) {
        _selectedNoteIds.remove(noteId);
        devtools.log("is present ${_selectedNoteIds.contains(noteId)}");
      } else {
        _selectedNoteIds.add(noteId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedNoteIds.clear();
      // _allSelected = false;
    });
  }

  //if allSelected, call deleteAllNOtes of user, else do batch deletion
  Future<void> _deleteSelected() async {
    final ids = _selectedNoteIds.toList();
    try {
      int deleted;
      if (_allNoteIds.length == _selectedNoteIds.length) {
        _allNoteIds.clear();
        DatabaseUser currentUser =
            await notesServices.getUser(email: user.email!);
        deleted = await notesServices.deleteAllNotesOfUser(currentUser.userId);
      } else {
        _allNoteIds.removeAll(_selectedNoteIds);
        deleted = await notesServices.deleteNotesInBatch(ids);
      }
      devtools.log("deleted notes=$deleted");
      _clearSelection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't delete selected notes")),
        );
      }
    }
  }

  void _toggleSelectAllNotes() {
    devtools.log("Calling toggle all notes");
    if (_selectedNoteIds.length != _allNoteIds.length) {
      setState(() {
        _selectedNoteIds.addAll(_allNoteIds);
      });
    } else {
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      //If user is selecting for batch operation and presses back, go back to dashboard
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _clearSelection(); // back press while selecting just clears selection, doesn't navigate
      },
      child: Scaffold(
          appBar: _isSelecting
              ? MyAppBar(
                  appTitle: Text("${_selectedNoteIds.length} selected"),
                  leadingIcon: IconButton(
                      onPressed: _toggleSelectAllNotes,
                      icon: Icon(_selectedNoteIds.length == _allNoteIds.length
                          ? Icons.check_box
                          : Icons.check_box_outline_blank)),
                  trailingIcons: [
                    IconButton(
                        onPressed: _clearSelection, icon: Icon(Icons.close)),
                    IconButton(
                        onPressed: () async {
                          int finalCount = _selectedNoteIds.length;
                          final bool deleteconfirm =
                              await warningPopUp(context, finalCount);
                          devtools.log("confirm delete = $deleteconfirm");
                          if (deleteconfirm) _deleteSelected();
                        },
                        icon: Icon(Icons.delete))
                  ],
                )
              : MyAppBar(
                  appTitle: Text("Notes"),
                  trailingIcons: [
                    IconButton(
                        onPressed: () async {
                          try {
                            await _initFuture; // no-op if already done, rethrows if init failed
                          } catch (_) {
                            return; // dashboard already shows its own error state
                          }
                          if (!context.mounted) return;
                          final result = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                                builder: (_) => const NewNoteView()),
                          );
                          if (result == false && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Failed to create New Note")),
                            );
                          }
                        },
                        icon: Icon(Icons.add))
                  ],
                ),
          body: FutureBuilder(
            future: _initFuture,
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.done:
                  if (snapshot.hasError) {
                    return const Scaffold(
                        body: Center(child: Text("Failed notes retrival...")));
                  }
                  return StreamBuilder(
                      stream: notesServices.allNotes,
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return CircularProgressIndicator();
                          case ConnectionState.active:
                            if (snapshot.hasData) {
                              final allNotes =
                                  snapshot.data as List<DatabaseNotes>;
                              for (final n in allNotes) {
                                _allNoteIds.add(n.noteId);
                              }
                              return dashBoardListView(allNotes);
                            } else {
                              return CircularProgressIndicator();
                            }
                          default:
                            return CircularProgressIndicator();
                        }
                      });
                default:
                  return CircularProgressIndicator();
              }
            },
          )),
    );
  }

  Widget dashBoardListView(List<DatabaseNotes> allNotes) {
    // _totalNotesOfUser = allNotes.length;
    return ListView.builder(
      itemCount: allNotes.length,
      itemBuilder: (context, index) {
        DatabaseNotes note = allNotes[index];
        final bool isSelected = _selectedNoteIds.contains(note.noteId);
        devtools.log(
            "noteId = ${allNotes[index].noteId}; isSelected = $isSelected");
        return Container(
          decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade100 : Colors.grey,
              borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.symmetric(vertical: 10),
          margin: EdgeInsets.symmetric(vertical: 10),
          child: ListTile(
            //long press enables notes selection for batch operation
            onLongPress: () => _toggleSelection(note.noteId),
            //If it is in selecting mode, just toggle whether note is getting selected or not
            onTap: _isSelecting
                ? () => _toggleSelection(note.noteId)
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ExistingNoteView(
                          note: note,
                        ), // Or leave it empty for a new note
                      ),
                    ),
            leading: _isSelecting
                ? Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.blue : Colors.grey.shade600,
                  )
                : null,
            style: ListTileStyle.list,
            title: Text(note.title),
            subtitle: Text(
              note.content,
              maxLines: 1,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Future<bool> warningPopUp(BuildContext context, int count) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Text(
              "$count notes will be deleted permanently\nConfirm?",
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.spaceAround,
            actions: [
              ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text("cancel")),
              ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text("confirm")),
            ],
          );
        }).then((value) => value ?? false);
  }
}
