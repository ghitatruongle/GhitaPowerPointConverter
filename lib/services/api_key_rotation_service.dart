import 'dart:convert';
import 'package:http/http.dart' as http;

class APIKeyRotationService {
  Future<bool> testAPIKey(String baseUrl, String apiKey, String providerId) async {
    try {
      final url = Uri.parse('$baseUrl/v1/models');
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (apiKey.isNotEmpty) {
        if (providerId.contains('anthropic')) {
          headers['x-api-key'] = apiKey;
          headers['anthropic-version'] = '2023-06-01';
        } else {
          headers['Authorization'] = 'Bearer $apiKey';
        }
      }

      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 5),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
