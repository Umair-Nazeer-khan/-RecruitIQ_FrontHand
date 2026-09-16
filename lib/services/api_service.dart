// lib/services/api_service.dart
// ─────────────────────────────────────────────────────────────
//  ALL HTTP calls to the Django backend.
//  Every method here is REAL — no hardcoded data anywhere.
// ─────────────────────────────────────────────────────────────

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
      throw ApiException(
          'The server took too long to respond. Please check your internet connection and try again.');
    } catch (e) {
      final text = e.toString();
      if (text.contains('SocketException') ||
          text.contains('Failed host lookup') ||
          text.contains('Connection refused') ||
          text.contains('Connection reset') ||
          text.contains('Connection closed') ||
          text.contains('Network is unreachable') ||
          text.contains('ClientException')) {
        throw ApiException(
            'No internet connection or the RecruitIQ server is unavailable. Please check your connection and try again.');
      }
      rethrow;
    }
  }

  static dynamic _handle(http.Response response) {
    final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    String message = switch (response.statusCode) {
      400 => 'Some information is invalid. Please check your input.',
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested service or record was not found.',
      408 => 'The request timed out. Please try again.',
      429 => 'Too many requests. Please wait a moment and try again.',
      >= 500 =>
        'RecruitIQ server is temporarily unavailable. Please try again shortly.',
      _ => 'Request could not be completed. Please try again.',
    };
    if (data is Map) {
      if (data['detail'] != null) {
        message = data['detail'].toString();
      } else if (data['errors'] != null) {
        // DRF field-validation errors look like: {"errors": {"file": ["..."]}}
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstKey = errors.keys.first;
          final firstVal = errors[firstKey];
          final text =
              firstVal is List ? firstVal.join(', ') : firstVal.toString();
          message = text;
        }
      } else if (data['error'] != null) {
        // Some endpoints (e.g. resume upload's parse-failure path) return
        // a singular 'error' string instead of 'errors'.
        message = data['error'].toString();
      } else if (data['message'] != null) {
        message = data['message'].toString();
      } else if (data['non_field_errors'] != null) {
        final list = data['non_field_errors'];
        message = list is List ? list.join(', ') : list.toString();
      }
    }
    throw ApiException(message);
  }

  static Future<dynamic> login(String email, String password) async {
    return _guard(() async {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/auth/login/'),
            headers: _headers(null),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      return _handle(res);
    });
  }

  /// Verifies if the current token is valid by fetching the user profile.
  static Future<bool> verifyToken(String accessToken) async {
    return _guard(() async {
      try {
        await getProfile(accessToken);
        return true;
      } catch (_) {
        return false;
      }
    });
  }

  static Future<dynamic> register(
      String name, String email, String password) async {
    return _guard(() async {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/auth/register/'),
            headers: _headers(null),
            body: jsonEncode(
                {'name': name, 'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
      return _handle(res);
    });
  }

  static Future<void> logout(String accessToken, String refreshToken) async {
    return _guard(() async {
      try {
        final res = await _client
            .post(
              Uri.parse('$baseUrl/auth/logout/'),
              headers: _headers(accessToken),
              body: jsonEncode({'refresh': refreshToken}),
            )
            .timeout(const Duration(seconds: 10));
        _handle(res);
      } catch (_) {
        // ignore network errors on logout
      }
    });
  }

  static Future<dynamic> getProfile(String accessToken) async {
    return _guard(() async {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/auth/profile/'),
            headers: _headers(accessToken),
          )
          .timeout(const Duration(seconds: 10));
      return _handle(res);
    });
  }

  // ════════════════════════════════════════════════
  //  RESUMES / CANDIDATES
  // ════════════════════════════════════════════════

  /// Takes the raw file bytes directly (not a path) so uploads work
  /// reliably regardless of where the file was picked from — local
  /// storage, Google Drive, or any other cloud-backed source where a
  /// plain file path can be unreadable or point to 0 bytes.
  static Future<Candidate> uploadResume(
      Uint8List bytes, String filename, String accessToken) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/resumes/upload/');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final streamed =
          await request.send().timeout(const Duration(seconds: 40));
      final response = await http.Response.fromStream(streamed);
      final data = _handle(response);
      return Candidate.fromJson(data['candidate']);
    });
  }

  static Future<List<Candidate>> getCandidates(String accessToken,
      {String? status}) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/resumes/').replace(
        queryParameters: status != null ? {'status': status} : null,
      );
      final res = await _client
          .get(uri, headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));
      final data = _handle(res);
      final List list = data['candidates'] ?? [];
      return list.map((e) => Candidate.fromJson(e)).toList();
    });
  }

  static Future<Candidate> getCandidateDetail(
      int id, String accessToken) async {
    return _guard(() async {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/resumes/$id/'),
            headers: _headers(accessToken),
          )
          .timeout(const Duration(seconds: 15));
      final data = _handle(res);
      return Candidate.fromJson(data);
    });
  }

  static Future<dynamic> getDashboardStats(String accessToken) async {
    return _guard(() async {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/resumes/stats/'),
            headers: _headers(accessToken),
          )
          .timeout(const Duration(seconds: 15));
      return _handle(res);
    });
  }

  static Future<void> updateCandidateStatus(
      int candidateId, String status, String accessToken,
      {String? notes}) async {
    return _guard(() async {
      final res = await _client
          .patch(
            Uri.parse('$baseUrl/resumes/$candidateId/status/'),
            headers: _headers(accessToken),
            body: jsonEncode({
              'status': status,
              if (notes != null) 'hr_notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 15));
      _handle(res);
    });
  }

  // ════════════════════════════════════════════════
  //  JOBS
  // ════════════════════════════════════════════════

  static Future<List<JobRequirement>> getJobs(String accessToken) async {
    return _guard(() async {
      final res = await _client
          .get(
            Uri.parse('$baseUrl/jobs/'),
            headers: _headers(accessToken),
          )
          .timeout(const Duration(seconds: 15));
      final data = _handle(res);
      final List list = data is List ? data : [];
      return list.map((e) => JobRequirement.fromJson(e)).toList();
    });
  }

  static Future<JobRequirement> createJob(
      JobRequirement job, String accessToken) async {
    return _guard(() async {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/jobs/'),
            headers: _headers(accessToken),
            body: jsonEncode(job.toJson()),
          )
          .timeout(const Duration(seconds: 15));
      final data = _handle(res);
      return JobRequirement.fromJson(data);
    });
  }

  // ════════════════════════════════════════════════
  //  AI MATCHING
  // ════════════════════════════════════════════════

  static Future<MatchResult> matchCandidates(
      JobRequirement job, String accessToken) async {
    return _guard(() async {
      final res = await _client
          .post(
            Uri.parse('$baseUrl/matching/match/'),
            headers: _headers(accessToken),
            body: jsonEncode(job.toMatchJson()),
          )
          .timeout(const Duration(seconds: 40));
      final data = _handle(res);
      return MatchResult.fromJson(data);
    });
  }

  static Future<List<Candidate>> getMatchResults(String accessToken,
      {double? minScore}) async {
    return _guard(() async {
      final uri = Uri.parse('$baseUrl/matching/results/').replace(
        queryParameters:
            minScore != null ? {'min_score': minScore.toString()} : null,
      );
      final res = await _client
          .get(uri, headers: _headers(accessToken))
          .timeout(const Duration(seconds: 15));
      final data = _handle(res);
      final List list = data['results'] ?? [];
      return list.map((e) => Candidate.fromMatchResult(e)).toList();
    });
  }
}
