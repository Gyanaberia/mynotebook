import 'package:flutter/material.dart';
import 'package:mynotebook/widgets/myappbar.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: MyAppBar(appTitle: "New Note"),);
  }
}