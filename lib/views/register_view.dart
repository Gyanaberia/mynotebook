import 'package:flutter/material.dart';
import 'package:google_analytics_methods/ga_methods.dart';
import 'package:mynotebook/services/auth/auth_exceptions.dart';
import 'package:mynotebook/services/auth/auth_service.dart';
import 'package:mynotebook/constants/routes.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  AnalyticsClass analytics = AnalyticsClass();

  late final TextEditingController _email;
  late final TextEditingController _password;
  late bool _registerLoader;
  final _registerKey = GlobalKey<FormState>();
  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    // _email.addListener(_emailListener);
    // _password.addListener(_passwordListener);
    _registerLoader = false;
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // void _emailListener(){
  //   RegExp emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  //   if(emailRegex.hasMatch(_email.text)){
  //     return;
  //   }else{

  //   }
  // }

  // void _passwordListener(){
  //   RegExp passLen = RegExp(r'^.{7,}$');
  //   if(passLen.hasMatch(_password.text)){
  //     return;
  //   }else{

  //   }
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Register"),
          backgroundColor: Colors.blue,
        ),
        body: Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              // EMAIL FIELD
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  hintText: "Enter your Email",
                  // labelText: "*",
                  labelStyle: TextStyle(color: Colors.grey),
                  helperMaxLines: 1,
                  floatingLabelStyle: TextStyle(color: Colors.red), // Changes label color to red on focus
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required'; // The red helper text
                  }
                  return null; 
                },
              ),
              SizedBox(height: 10,),

              TextFormField(
                controller: _password,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  // labelText: "*",
                  hintText: "Enter Password",
                  labelStyle: TextStyle(color: Colors.grey),
                  floatingLabelStyle: TextStyle(color: Colors.red),
                  helperMaxLines: 1
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required'; // The red helper text
                  }
                  return null;
                },
              ),
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () async{
                  // Triggers validation manually when the user tries to submit
                  if (_registerKey.currentState!.validate()) {
                    final email = _email.text;
                    final password = _password.text;
                      setState(() {
                        _registerLoader = true;
                      });
                      await register(email, password);
                      if(context.mounted) {
                          setState(() {
                          _registerLoader = false;
                        });
                      }
                  }
                },
                child:_registerLoader
                      ? CircularProgressIndicator()
                      : const Text("Register"),
              ),
              SizedBox(height: 10,),
              TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(loginRoute, (route) => false);
                  },
                  child:  const Text("Already have an account? Login here!"))
            ],
          ),
        ));
  }

  Future<void> register(String email, String password) async {
    final message = ScaffoldMessenger.of(context);

    try {
      AuthService authService = AuthService.firebase();

      //Register user
      await authService.createUser(userId: email, password: password);
      message.showSnackBar(const SnackBar(content: Text("User registered")));

      //Send email
      authService.sendEmailVerification();
      analytics.signupEvent('analytics signup');
      // ignore: use_build_context_synchronously
      Navigator.of(context).pushNamedAndRemoveUntil(verifyRoute,(route) => false);
    } on WeakPasswordAuthException {
      message.showSnackBar(const SnackBar(content: Text("Weak Password")));
    } on InvalidEmailAuthException {
      message.showSnackBar(const SnackBar(content: Text("Invalid Email")));
    } on EmailAlreadyInUseAuthEXception {
      message
          .showSnackBar(const SnackBar(content: Text("Email already in use")));
    } on GeneralAuthException {
      message.showSnackBar(const SnackBar(
          content: Text("Some error Occured. Please try again.")));
    }
  }
}
