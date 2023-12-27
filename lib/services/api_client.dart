import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:lemon_app/models/UserLocation.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({
    required TokenProvider tokenProvider,
    http.Client? httpClient,
  }) : this._(
          baseUrl: 'http://localhost:8080',
          tokenProvider: tokenProvider,
          httpClient: httpClient,
        );

  ApiClient._({
    required TokenProvider tokenProvider,
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl,
        _httpClient = httpClient ?? http.Client(),
        _tokenProvider = tokenProvider;

  final TokenProvider _tokenProvider;
  final String _baseUrl;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> sendSos(UserLocation userLocation) async {
    final url = Uri.parse('http://localhost:8080/v1/caregiver/help');
    final response = await _handleRequest((headers) => _httpClient.post(
          url,
          headers: headers,
          body: userLocation.toJson(),
        ));

    return response;
  }

  Future<Map<String, dynamic>> _handleRequest(
    Future<http.Response> Function(Map<String, String>) request,
  ) async {
    try {
      final headers = await _getRequestHeaders();
      final response = await request(headers);
      final body = jsonDecode(response.body);

      if (response.statusCode != HttpStatus.ok) {
        throw Exception('${response.statusCode}, error: ${body['message']}');
      }

      return body;
    } on TimeoutException {
      throw Exception('Request timeout. Please try again');
    } catch (err) {
      throw Exception('Unexpected error: $err');
    }
  }

  Future<Map<String, String>> _getRequestHeaders() async {
    final token = await _tokenProvider();

    return <String, String>{
      HttpHeaders.contentTypeHeader: ContentType.json.value,
      HttpHeaders.acceptHeader: ContentType.json.value,
      if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
    };
  }
}
