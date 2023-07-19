class Station {
  final String name;
  final String latitude;
  final String longitude;
  final String driverId;

  Station(
      {required this.name,
      required this.latitude,
      required this.longitude,
      required this.driverId});

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
        name: json['name'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        driverId: json['driverId']);
  }
}
