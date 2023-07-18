import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bus_tracking_system/screen/profile.dart';
import 'package:geolocator/geolocator.dart';
import 'locations_page.dart';

class DriverDestinationPage extends StatefulWidget {
  const DriverDestinationPage({Key? key}) : super(key: key);

  @override
  _DriverDestinationPageState createState() => _DriverDestinationPageState();
}

class _DriverDestinationPageState extends State<DriverDestinationPage> {
  final _destinationController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  Timer? locationTimer;

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

  void startLocationUpdates() {
    locationTimer =
        Timer.periodic(const Duration(seconds: 20), (Timer t) async {
      var currentLocation = await _getCurrentLocation();
      _longitudeController.text = currentLocation.longitude.toString();
      _latitudeController.text = currentLocation.latitude.toString();
      _updateLocationToFirebase();
    });
  }

  void _insertLocationToFirebase() {
    _firebaseFirestore
        .collection('drivers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      'destination': _destinationController.text,
      'longitude': double.parse(_longitudeController.text),
      'latitude': double.parse(_latitudeController.text),
    }, SetOptions(merge: true));
  }

  Future<Position> _getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  final DatabaseReference _firebaseDatabase = FirebaseDatabase.instance.ref();

  void _updateLocationToFirebase() {
    _firebaseDatabase
        .child('drivers/${FirebaseAuth.instance.currentUser!.uid}')
        .set({
      'destination': _destinationController.text,
      'longitude': double.parse(_longitudeController.text),
      'latitude': double.parse(_latitudeController.text),
    });
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
              leading: const Icon(Icons.map),
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
              leading: const Icon(Icons.account_circle),
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
              leading: const Icon(Icons.exit_to_app),
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
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'Enter the name of your destination',
              ),
            ),
            TextField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'Enter the longitude of your destination',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'Enter the latitude of your destination',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _insertLocationToFirebase,
              child: const Text('Set Destination'),
            )
          ],
        ),
      ),
    );
  }
}
