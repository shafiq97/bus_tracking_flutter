import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

import 'direction_map.dart';

class NearbyBusStations extends StatefulWidget {
  @override
  _NearbyBusStationsState createState() => _NearbyBusStationsState();
}

class _NearbyBusStationsState extends State<NearbyBusStations> {
  LatLng? _center;
  List<Map<String, dynamic>> stations = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  _fetchCurrentLocation() async {
    final location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    setState(() {
      _center = LatLng(_locationData.latitude!, _locationData.longitude!);
    });

    _fetchNearbyBusStations();
  }

  _fetchNearbyBusStations() async {
    if (_center == null) return;

    // Use Google Places API to fetch bus stations
    String apiKey = 'AIzaSyC9XbLY2QHCWNqpzwZa74mfvt19Otk4ZIw';
    String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_center!.latitude},${_center!.longitude}&radius=1500&type=bus_station&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['results'] != null) {
      setState(() {
        stations = List<Map<String, dynamic>>.from(data['results']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nearby Bus Stations')),
      body: ListView.builder(
        itemCount: stations.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(stations[index]['name']),
            onTap: () {
              _showBusStationDetails(stations[index]);
            },
          );
        },
      ),
    );
  }

  _showBusStationDetails(Map<String, dynamic> station) {
    LatLng destination = LatLng(station['geometry']['location']['lat'],
        station['geometry']['location']['lng']);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DirectionMap(
        origin: _center!,
        destination: destination,
      ),
    ));
  }
}
