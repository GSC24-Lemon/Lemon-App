class UserLocation {
  const UserLocation({
    required this.deviceId,
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
  final String deviceId;

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
        deviceId: json['deviceId'] ?? '',
        latitude: json['lat'] ?? '',
        longitude: json['long'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'lat': latitude,
      'long': longitude,
    };
  }

  @override
  List<Object?> get props => [deviceId, latitude, longitude];
}
