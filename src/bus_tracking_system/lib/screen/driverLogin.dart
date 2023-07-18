import 'package:bus_tracking_system/screen/driver_destination.dart';
import 'package:bus_tracking_system/screen/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bus_tracking_system/Constants/constants.dart';
import 'package:bus_tracking_system/helper/helperFunction.dart';
import 'package:bus_tracking_system/screen/maps.dart';
import 'package:bus_tracking_system/screen/splash.dart';
import 'package:bus_tracking_system/services/authServices.dart';
import 'package:bus_tracking_system/services/databaseServices.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bus_tracking_system/componentes/MyButton.dart';
import 'package:bus_tracking_system/componentes/My_TextField.dart';

import 'locations_page.dart';

class DriverLogin extends StatefulWidget {
  const DriverLogin({Key? key}) : super(key: key);

  @override
  State<DriverLogin> createState() => _DriverLoginState();
}

class _DriverLoginState extends State<DriverLogin> {
  final AuthService _auth = AuthService();
  bool isStudent = true;
  late final String email;
  late final String password;
  final _formKey = GlobalKey<FormState>(); // Updated key name
  final emailController = TextEditingController();
  final passController = TextEditingController();
  bool passToggle = false;

  get validator => null;

  void toggleLoginOption() {
    setState(() {
      isStudent = !isStudent;
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) {
          return const UI();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Color(0xFFF8F8F8),
      backgroundColor: const Color(0xFFF8F9FD),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              //backgroundColor: Color.fromARGB(255, 224, 224, 244),

              // backgroundColor: Color(0xFFE8F5E9),

              const SizedBox(height: 100),
              const Text(
                'Driver Login',
                style: TextStyle(
                  //color: Color(0xFF34BAC3),
                  color: Color(0xFF1CBBBE),
                  fontFamily: 'Avenir',
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.bold,
                  fontSize: 50,
                ),
              ),
              const SizedBox(height: 80),
              MyTextField(
                controller: emailController,
                obscureText: false,
                hintText: 'Enter driver email',
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
                  hintText: 'Enter bus-driver email',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(169, 106, 196, 207),
                    fontSize: 18.0,
                  ),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 20),

              MyTextField(
                keyboardType: TextInputType.emailAddress,
                controller: passController,
                obscureText: passToggle,
                decoration: InputDecoration(
                  suffixIcon: InkWell(
                    onTap: () {
                      setState(() {
                        passToggle = !passToggle;
                      });
                    },
                    child: Icon(
                      passToggle ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Enter Password';
                  } else if (passController.text.length < 9) {
                    return "Password length should be more than 9 characters";
                  }
                  return null;
                },
                hintText: 'Password',
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: toggleLoginOption,
                child: const Text(
                  'Log in as student',
                  style: TextStyle(fontSize: 20),
                  selectionColor: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 150),
              MyButton(
                label: 'Login',
                onTap: () async {
                  if (_formKey.currentState!.validate()) {
                    String password = passController.text;
                    dynamic result = await _auth.loginWithUserEmailandPassword(
                      emailController.text,
                      password,
                    );
                    if (result ==
                        'There is no user record corresponding to this identifier. The user may have been deleted.') {
                      // Handle login failure
                    } else {
                      // ignore: use_build_context_synchronously
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) {
                            return const DriverDestinationPage();
                          },
                        ),
                      );
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
