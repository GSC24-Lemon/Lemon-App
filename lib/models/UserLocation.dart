import 'package:equatable/equatable.dart';

class UserLocation extends Equatable {
  const UserLocation({
    required this.deviceId,
    required this.latitude,
    required this.longitude,
     this.username,
     this.destination,
  });

  final double latitude;
  final double longitude;
  final String deviceId;
  final String? username;
  final String?destination;

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      deviceId: json['deviceId'] ?? '',
      latitude: json['latitude'] ?? '',
      longitude: json['longitude'] ?? '',
      username: json['username'] ?? '',
      destination: json['destination'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'username': username,
      'destination': destination,
    };
  }

  @override
  List<Object?> get props => [deviceId, latitude, longitude];
}
