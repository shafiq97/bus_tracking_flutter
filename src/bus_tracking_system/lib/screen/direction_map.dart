import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionMap extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;

  DirectionMap({required this.origin, required this.destination});

  @override
  _DirectionMapState createState() => _DirectionMapState();
}

class _DirectionMapState extends State<DirectionMap> {
  late GoogleMapController mapController;
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _getPolyline();
  }

  Future<List<LatLng>> getDirections(
      {required LatLng origin, required LatLng destination}) async {
    String apiKey = 'AIzaSyC9XbLY2QHCWNqpzwZa74mfvt19Otk4ZIw';
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['routes'] == null || data['routes'].isEmpty) return [];

    String encodedPoly = data['routes'][0]['overview_polyline']['points'];
    return decodePoly(encodedPoly);
  }

  List<LatLng> decodePoly(String encoded) {
    int index = 0;
    final List<LatLng> path = [];
    int len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final double latD = lat / 1e5;
      final double lngD = lng / 1e5;
      path.add(LatLng(latD, lngD));
    }

    return path;
  }

  _getPolyline() async {
    List<LatLng> polylinePoints = await getDirections(
        origin: widget.origin, destination: widget.destination);
    setState(() {
      _polylines.add(
        Polyline(
          polylineId: PolylineId('route1'),
          visible: true,
          points: polylinePoints,
          color: Colors.blue,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Directions')),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        polylines: _polylines,
        initialCameraPosition:
            CameraPosition(target: widget.origin, zoom: 15.0),
      ),
    );
  }
}
