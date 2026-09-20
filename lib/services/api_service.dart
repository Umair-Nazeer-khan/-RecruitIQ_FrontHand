// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl =
      "https://recruitiq-backend-production-d702.up.railway.app/api/v1";
  static final http.Client _client = http.Client();

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on TimeoutException {
      throw ApiException('The RecruitIQ server is taking too long to respond. Please check your internet connection.');
    } catch (e) {
      if (e is ApiException) rethrow;
      final text = e.toString().toLowerCase();
      if (text.contains('socketexception') || text.contains('connection') || text.contains('host lookup')) {
        throw ApiException('Unable to connect to RecruitIQ. Please check your internet connection.');
      }
      throw ApiException('A network error occurred. Please try again.');
    }
  }

  static dynamic _handle(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/json')) {
      if (response.statusCode >= 500) {
        throw ApiException('Server error (500). Our AI engineers are looking into it.');
      }
      throw ApiException('Received an unexpected response from the server.');
    }

    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
    if (response.statusCode >= 200 && response.statusCode < 300) return data;

    String message = 'The request could not be completed (Error ${response.statusCode}).';
    if (data is Map) {
      if (data['detail'] != null) {
        message = data['detail'].toString();
      } else if (data['error'] != null) {
        message = data['error'].toString();
      } else if (data['message'] != null) {
        message = data['message'].toString();
      } else if (data['errors'] != null && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) message = errors.values.first.toString();
      }
    }
    throw ApiException(message);
  }

  // ── AUTHENTICATION ──────────────────────────────────────────

  static Future<dynamic> login(String email, String password) async {
    return _guard(() async {
      final res = await _client.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: _headers(null),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));
      return _handle(res);
    });
  }

  static Future<dynamic> register(String name, String email, String password) async {
    return _guard(() async {
      final res = await _client.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: _headers(null),
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));
      return _handle(res);
    });
  }

  static Future<void> logout(String accessToken, String refreshToken) async {
    return _guard(() async {
      try {
        final res = await _client.post(
          Uri.parse('$baseUrl/auth/logout/'),
          headers: _headers(accessToken),
          body: jsonEncode({'refresh': refreshToken}),
        ).timeout(const Duration(seconds: 10));
        _handle(res);
      } catch (_) {}
    });
  }

  static Future<dynamic> getProfile(String accessToken) async {
    return _guard(() async {
      final res = await _client.get(
        Uri.parse('$baseUrl/auth/profile/'),
        headers: _headers(accessToken),
      ).timeout(const Duration(seconds: 10));
      return _handle(res);
    });
  }

  // ── CORE FEATURES ───────────────────────────────────────────

  static Future<Candidate> uploadResume(Uint8List bytes, String filename, String accessToken) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/resumes/upload/');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final streamed = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamed);
      final data = _handle(response);
      
      if (data is Map && data.containsKey('candidate')) {
        return Candidate.fromJson(data['candidate']);
      }
      throw ApiException('Parsed resume data was missing from the server response.');
    });
  }

  static Future<List<Candidate>> getCandidates(String accessToken, {String? status}) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/resumes/').replace(
        queryParameters: status != null ? {'status': status} : null,
      );
      final res = await _client.get(uri, headers: _headers(accessToken)).timeout(const Duration(seconds: 20));
      final data = _handle(res);
      final List list = data['candidates'] ?? [];
      return list.map((e) => Candidate.fromJson(e)).toList();
    });
  }

  static Future<Candidate> getCandidateDetail(int id, String accessToken) async {
    return _guard(() async {
      final res = await _client.get(Uri.parse('$baseUrl/resumes/$id/'), headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));
      final data = _handle(res);
      return Candidate.fromJson(data);
    });
  }

  static Future<void> updateCandidateStatus(int id, String status, String accessToken) async {
    return _guard(() async {
      final res = await _client.patch(
        Uri.parse('$baseUrl/resumes/$id/'),
        headers: _headers(accessToken),
        body: jsonEncode({'status': status}),
      ).timeout(const Duration(seconds: 15));
      _handle(res);
    });
  }

  static Future<MatchResult> matchCandidates(JobRequirement job, String accessToken) async {
    return _guard(() async {
      final res = await _client.post(
        Uri.parse('$baseUrl/matching/match/'),
        headers: _headers(accessToken),
        body: jsonEncode(job.toMatchJson()),
      ).timeout(const Duration(seconds: 60));
      final data = _handle(res);
      return MatchResult.fromJson(data);
    });
  }

  static Future<List<JobRequirement>> getJobs(String accessToken) async {
    return _guard(() async {
      final res = await _client.get(Uri.parse('$baseUrl/jobs/'), headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));
      final data = _handle(res);
      final List list = data is List ? data : (data['jobs'] ?? []);
      return list.map((e) => JobRequirement.fromJson(e)).toList();
    });
  }
}
