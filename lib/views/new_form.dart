import 'package:flutter/material.dart';
import 'package:mynotebook/constants/routes.dart';
import 'package:mynotebook/widgets/myappbar.dart';
import 'package:gaform_1/gaform_1.dart';

class NewCustomForm extends StatelessWidget {
  const NewCustomForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(appTitle: "Custom Form", appBar: AppBar()),
      body: const CustomForm(
        completionRoute: notesRoute,
      ),
    );
  }
}
