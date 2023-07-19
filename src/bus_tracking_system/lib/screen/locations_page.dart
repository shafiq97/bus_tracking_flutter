import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:bus_tracking_system/screen/maps.dart';
import 'package:bus_tracking_system/screen/profile.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../model/station.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  _LocationsPageState createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  Location location = Location();
  LocationData? locationData;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;

  Stream<List<Station>> fetchLocationsFromFirestore() {
    return _firebaseFirestore.collection('drivers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Station(
            name: doc['destination'],
            latitude: doc['latitude'],
            longitude: doc['longitude'],
            driverId: doc['driverId']);
      }).toList();
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
        backgroundColor: Colors.white,
        title: const Text(
          'Select Route',
          style: TextStyle(color: Colors.black),
        ),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              color: Colors.black,
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_pin),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Current Location'),
                    content: Text(
                        'Lat: ${locationData?.latitude}, Long: ${locationData?.longitude}'),
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
            },
          ),
        ],
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
      body: StreamBuilder<List<Station>>(
        stream: fetchLocationsFromFirestore(),
        builder: (BuildContext context, AsyncSnapshot<List<Station>> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          } else {
            List<Station> stations = snapshot.data!;
            return ListView.builder(
              itemCount: stations.length,
              itemBuilder: (BuildContext context, int index) {
                Station station = stations[index];
                return ListTile(
                  title: Text(station.name),
                  subtitle: Text(
                      'Latitude: ${station.latitude.toString()}, Longitude: ${station.longitude.toString()}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusTracking(station: station),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
