import 'dart:async';
import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracking_system/componentes/MyButton.dart';
import 'package:bus_tracking_system/componentes/My_TextField.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:bus_tracking_system/screen/profile.dart';

import 'locations_page.dart';

class DriverDestinationPage2 extends StatefulWidget {
  const DriverDestinationPage2({Key? key}) : super(key: key);

  @override
  _DriverDestinationPage2State createState() => _DriverDestinationPage2State();
}

class _DriverDestinationPage2State extends State<DriverDestinationPage2> {
  final _destinationController = TextEditingController();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  Prediction? _selectedPrediction;
  final _longitudeController = TextEditingController();
  final _latitudeController = TextEditingController();
  Timer? locationTimer;

  void startLocationUpdates() {
    locationTimer =
        Timer.periodic(const Duration(seconds: 20), (Timer t) async {
      var currentLocation = await _getCurrentLocation();
      _longitudeController.text = currentLocation.longitude.toString();
      _latitudeController.text = currentLocation.latitude.toString();
      _updateLocationToRealTimeFirebase();
    });
  }

  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  final DatabaseReference _firebaseDatabase = FirebaseDatabase.instance.ref();

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    startLocationUpdates();
  }

  void _updateLocationToRealTimeFirebase() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DatabaseReference driverRef = _firebaseDatabase.child('drivers/$uid');

    driverRef.set({
      'destination': _destinationController.text,
      'longitude': double.parse(_longitudeController.text),
      'latitude': double.parse(_latitudeController.text),
    }).then((_) {
      // Successfully wrote to the database
      log("success");
    }).catchError((error) {
      // There was an error writing to the database
      print(error);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update location.')));
    });
  }

  Future<void> _updateLocationToFirebase() async {
    if (_selectedPrediction != null) {
      try {
        await _firebaseFirestore.collection('drivers').add({
          'destination': _destinationController.text,
          'longitude': _selectedPrediction!.lng,
          'latitude': _selectedPrediction!.lat,
          'driverId': FirebaseAuth.instance.currentUser!.uid,
        });

        // Show the success dialog
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Location updated successfully!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        // Handle any errors here. Maybe show an error dialog or print the error.
        print("Error updating location: $e");
      }
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Do you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                // Perform logout operation
                Navigator.of(context).pop();
                // Add your logout logic here
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('No'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Destination'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Select Route'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationsPage(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(),
                  ),
                );
              },
            ),
            ListTile(
              title: const Text('Logout'),
              onTap: _showLogoutConfirmationDialog,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GooglePlaceAutoCompleteTextField(
                  textEditingController: _destinationController,
                  googleAPIKey: "AIzaSyC9XbLY2QHCWNqpzwZa74mfvt19Otk4ZIw",
                  inputDecoration:
                      const InputDecoration(hintText: "Search your location"),
                  debounceTime: 800,
                  countries: const ["my"],
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    print("placeDetails" + prediction.lng.toString());
                  },
                  itmClick: (Prediction prediction) {
                    _destinationController.text = prediction.description!;
                    _selectedPrediction = prediction;
                    _destinationController.selection =
                        TextSelection.fromPosition(TextPosition(
                            offset: prediction.description!.length));
                  }),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                if (_destinationController.text.isNotEmpty) {
                  // Update destination in your database
                  await _updateLocationToFirebase();
                }
              },
              child: const Text('Set Destination'),
            ),
          ],
        ),
      ),
    );
  }
}
