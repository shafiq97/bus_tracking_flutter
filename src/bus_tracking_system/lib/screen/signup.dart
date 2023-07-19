import 'package:bus_tracking_system/screen/ui.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracking_system/services/authServices.dart';
import 'package:bus_tracking_system/componentes/MyButton.dart';
import 'package:bus_tracking_system/componentes/My_TextField.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();
  final fullNameController = TextEditingController();

  bool passToggle = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 100),
              const Text(
                'Sign Up',
                style: TextStyle(
                  color: Color(0xFF1CBBBE),
                  fontFamily: 'Avenir',
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                ),
              ),
              MyTextField(
                controller:
                    fullNameController, // 2. Add TextField for full name
                obscureText: false,
                hintText: 'Enter Full Name',
                validator: (value) {
                  if (value!.isEmpty) {
                    return "Enter Full Name";
                  }
                  return null;
                },
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  hintText: 'Enter Full Name',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(169, 106, 196, 207),
                    fontSize: 18.0,
                  ),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 80),
              MyTextField(
                controller: emailController,
                obscureText: false,
                hintText: 'Enter Email',
                validator: (value) {
                  bool emailValid = RegExp(
                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-z0-9]+\.[a-zA-Z]+")
                      .hasMatch(value!);
                  if (value.isEmpty) {
                    return "Enter Email";
                  } else if (!emailValid) {
                    return "Enter valid Email";
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Enter Email',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(169, 106, 196, 207),
                    fontSize: 18.0,
                  ),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 20),
              MyTextField(
                controller: passController,
                obscureText: passToggle,
                hintText: 'Password',
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Enter Password';
                  } else if (passController.text.length < 9) {
                    return "Password length should be more than 9 characters";
                  }
                  return null;
                },
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 20),
              MyTextField(
                controller: confirmPassController,
                obscureText: passToggle,
                hintText: 'Confirm Password',
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Confirm Password';
                  } else if (confirmPassController.text !=
                      passController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 150),
              MyButton(
                label: 'Sign Up',
                onTap: () async {
                  if (_formKey.currentState!.validate()) {
                    String password = passController.text;
                    bool success = await _auth.registerUserWithEmailandPassword(
                        fullNameController.text,
                        emailController.text,
                        password);

                    if (success) {
                      // ignore: use_build_context_synchronously
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Success'),
                            content:
                                const Text('You have successfully signed up!'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Okay'),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the dialog
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (BuildContext context) {
                                        return const UI();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      // handle error. Show another dialog or a snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Registration failed')));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
