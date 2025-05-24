import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:google_analytics_methods/ga_methods.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
import 'package:mynotebook/constants/routes.dart';
import 'package:mynotebook/widgets/myappbar.dart';
import '../widgets/custom_input.dart';
// import 'package:stepper_widget/widgets/custom_input.dart';

class FormPage extends StatefulWidget {
  const FormPage({Key? key}) : super(key: key);

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  AnalyticsClass analytics = AnalyticsClass();
  int currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        appTitle: "Stepper Widget ",
        appBar: AppBar(),
      ),
      body: Container(
          padding: const EdgeInsets.all(20),
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: currentStep,
            onStepCancel: () => currentStep == 0
                ? Navigator.of(context)
                    .pushNamedAndRemoveUntil(notesRoute, (route) => false)
                : setState(() {
                    currentStep -= 1;
                  }),
            onStepContinue: () {
              bool isLastStep = (currentStep == getSteps().length - 1);
              if (isLastStep) {
                final user = AuthService.firebase().currentUser;
                log(user?.email ?? "Not found");

                analytics.logCustomEvent('form_complete',
                    {'user_email': user?.email ?? "not found"});

                analytics.logCustomEvent('form_1', {'step': "4)Complete"});

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Form Submitted"),
                ));
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(notesRoute, (route) => false);
              } else {
                if (currentStep == 0) {
                  analytics.logCustomEvent('form_1', {'step': "2)Address"});
                } else {
                  analytics.logCustomEvent('form_1', {'step': "3)Misc"});
                }
                setState(() {
                  currentStep += 1;
                });
              }
            },
            onStepTapped: (step) => setState(() {
              currentStep = step;
            }),
            steps: getSteps(),
          )),
    );
  }

  List<Step> getSteps() {
    return <Step>[
      Step(
        state: currentStep > 0 ? StepState.complete : StepState.indexed,
        isActive: currentStep >= 0,
        title: const Text("Account Info"),
        content: const Column(
          children: [
            CustomInput(
              hint: "First Name",
              inputBorder: OutlineInputBorder(),
            ),
            CustomInput(
              hint: "Last Name",
              inputBorder: OutlineInputBorder(),
            ),
          ],
        ),
      ),
      Step(
        state: currentStep > 1 ? StepState.complete : StepState.indexed,
        isActive: currentStep >= 1,
        title: const Text("Address"),
        content: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Personal Details"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: 50,
                  width: 500,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "First Name",
                      border: OutlineInputBorder(),
                      // isDense: true,
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  width: 500,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Second Name",
                      border: OutlineInputBorder(),
                      // isDense: true,
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  height: 50,
                  width: 500,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Email ID",
                      border: OutlineInputBorder(),
                      // isDense: true,
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  width: 500,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Phone Number",
                      border: OutlineInputBorder(),
                      // isDense: true,
                      contentPadding: EdgeInsets.all(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      Step(
        state: currentStep > 2 ? StepState.complete : StepState.indexed,
        isActive: currentStep >= 2,
        title: const Text("Misc"),
        content: const Column(
          children: [
            CustomInput(
              hint: "Bio",
              inputBorder: OutlineInputBorder(),
            ),
          ],
        ),
      ),
    ];
  }
}
