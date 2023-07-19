import 'dart:convert';
import 'dart:developer';
import 'package:app_settings/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../Constants/constants.dart';
import 'package:bus_tracking_system/screen/profile.dart';
import 'package:bus_tracking_system/screen/locations_page.dart';

import '../model/station.dart';

class BusTracking extends StatefulWidget {
  final Station station;
  const BusTracking({Key? key, required this.station}) : super(key: key);
  @override
  _BusTrackingState createState() => _BusTrackingState();
}

class _BusTrackingState extends State<BusTracking> {
  String apiKey =
      "5b3ce3597851110001cf62484ed1f62b679d4f4395440958e2c058fa"; //OpenRouteService API key
  late String distance = '';
  late String time = '';

  bool isLoading = false; //A flag to check the status of the api data loading

  late LatLng sourceLocation = const LatLng(0, 0); //For user location
  late LatLng destinationLocation = LatLng(
      (double.parse(widget.station.latitude)), // For destination location
      (double.parse(widget.station.longitude)));
//Destination Location (retrieved from the firebase database; must be connected to firebase)
  List<LatLng> polylinePoints = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  late DatabaseReference dbRef;

  @override
  void initState() {
    super.initState();
    initNotifications();
    requestPermission();

    dbRef = FirebaseDatabase.instance
        .ref()
        .child('drivers'); //Change 'location' to your actual location node

    Stream.periodic(Duration(seconds: 15)).listen((_) {
      dbRef.once().then((DatabaseEvent event) {
        Map<dynamic, dynamic>? data = event.snapshot.value as Map?;
        if (data != null && data.isNotEmpty) {
          String destinationString = data['destinationLocation'];
          String sourceString = data['sourceLocation'];

          var destinationLat = double.parse(
              destinationString.split('(')[1].split(',')[0].split(':')[1]);
          var destinationLng = double.parse(
              destinationString.split('longitude:')[1].split(')')[0]);

          var sourceLat = double.parse(
              sourceString.split('(')[1].split(',')[0].split(':')[1]);
          var sourceLng =
              double.parse(sourceString.split('longitude:')[1].split(')')[0]);

          setState(() {
            destinationLocation = LatLng(
              destinationLat,
              destinationLng,
            );

            sourceLocation = LatLng(
              sourceLat,
              sourceLng,
            );
          });
        }
      });
    });
  }

//Permission to access live-location
  Future<void> requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
              'This app needs to access your location to work properly.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Settings'),
              onPressed: () => AppSettings.openAppSettings(),
            ),
          ],
        ),
      );
    } else if (permission == LocationPermission.deniedForever) {
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
              'This app needs to access your location to work properly.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Settings'),
              onPressed: () => AppSettings.openAppSettings(),
            ),
          ],
        ),
      );
    } else {
      getCurrentLocation();
    }
  }

  //Extraction of Live-location
  Future<void> getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      sourceLocation = LatLng(position.latitude, position.longitude);
    });
    fetchPolyline(sourceLocation, destinationLocation).then((points) {
      setState(() {
        polylinePoints = points;
      });
    });
  }

  //Time format
  String formatTime(double duration) {
    if (duration >= 60) {
      int hours = duration ~/ 60;
      int minutes = (duration % 60).toInt();
      return '${hours}h ${minutes}m';
    } else {
      return '${duration.round()}min';
    }
  }

  //Notification Alert for Bus_Arrival
  Future<void> initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'bus_arrival_channel',
      'Bus Arrival',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Bus is about to reach',
      'The bus will arrive within 2 minutes.',
      platformChannelSpecifics,
    );
  }

  //Calculate distance and time through an API request using OpenRouteService API
  Future<void> calculateDistanceAndTime() async {
    setState(() {
      isLoading = true;
    });

    String url =
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${sourceLocation.longitude},${sourceLocation.latitude}&end=${destinationLocation.longitude},${destinationLocation.latitude}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final route = jsonResponse['features'][0]['properties'];
        setState(() {
          distance =
              (route['segments'][0]['distance'] / 1000).toStringAsFixed(2) +
                  "km";
          double duration = (route['segments'][0]['duration'] / 60);
          time = formatTime(duration);
        });
        //This will display an alert that the bus is near
        // if (double.parse(time) <= 2) {
        //   showNotification();
        // }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  //Fetching polylines points via the ORS API
  Future<List<LatLng>> fetchPolyline(LatLng source, LatLng destination) async {
    final response = await http.get(Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$apiKey&start=${source.longitude},${source.latitude}&end=${destination.longitude},${destination.latitude}'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final coordinates =
          jsonResponse['features'][0]['geometry']['coordinates'];
      return coordinates
          .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
          .toList();
    } else {
      throw Exception('Failed to load polyline');
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
    final bool isDistanceTimeVisible = distance.isNotEmpty && time.isNotEmpty;
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
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: destinationLocation,
                zoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 30.0,
                      height: 30.0,
                      point: sourceLocation,
                      builder: (ctx) => Container(
                        child: Image.asset(
                          'assets/images/person.png', //Custom Person icon
                          width: 5.0,
                          height: 5.0,
                        ),
                      ),
                    ),
                    Marker(
                      width: 35.0,
                      height: 35.0,
                      point: destinationLocation,
                      builder: (ctx) => Image.asset(
                        'assets/images/busicon.png', //Custom Bus icon
                        width: 5.0,
                        height: 5.0,
                      ),
                    ),
                  ],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  'Distance: $distance',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  'Time: $time',
                  style: const TextStyle(fontSize: 16),
                ),
                // MaterialButton(
                //   onPressed: () {
                //     Set<String> values = {
                //       'Distance: $distance',
                //       'Time: $time',
                //     };

                //     dbRef.push().set(values);
                //   },
                // ),
                if (!isDistanceTimeVisible)
                  // calculateDistanceAndTime();isLoading ? null : calculateDistanceAndTime,
                  ElevatedButton(
                    onPressed: () {
                      isLoading
                          ? null
                          : calculateDistanceAndTime().then((value) {
                              Map<String, String> values = {
                                'Distance': distance,
                                'Time': time,
                                'sourceLocation': sourceLocation.toString(),
                                'destinationLocation':
                                    destinationLocation.toString(),
                              };
                              dbRef.push().set(values);
                            });
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                          if (states.contains(MaterialState.disabled)) {
                            return Colors.grey;
                          }
                          return Colors
                              .blue; //when ORS api data fetching is successful and it is ready to show required data(distance and time)
                        },
                      ),
                    ),
                    child: const Text('Show Distance & Time'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
