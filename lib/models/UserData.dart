class UserData {
  const UserData({
    required this.username,
    required this.telephone,
    required this.deviceId,
  });

  final String telephone;
  final String deviceId;
  final String username;

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
        username: json['username'] ?? '',
        telephone: json['telephone'] ?? '',
        deviceId: json['deviceId'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'telephone': telephone,
      'deviceId': deviceId,
    };
  }

  @override
  List<Object?> get props => [username, telephone, deviceId];
}
