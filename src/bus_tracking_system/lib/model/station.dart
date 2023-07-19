class Station {
  final String name;
  final String latitude;
  final String longitude;

  Station({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}
