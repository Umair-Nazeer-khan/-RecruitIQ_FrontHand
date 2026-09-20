// lib/viewmodels/dashboard_viewmodel.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../utils/error_message.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';

// ══════════════════════════════════════════════
//  DASHBOARD VIEWMODEL
// ══════════════════════════════════════════════
class DashboardViewModel extends ChangeNotifier {
  bool _isLoading = false;
  List<Candidate> _candidates = [];
  int _totalCVs = 0;
  int _shortlisted = 0;
  int _openJobs = 0;
  String? _error;

  bool get isLoading => _isLoading;
  List<Candidate> get candidates => _candidates;
  int get totalCVs => _totalCVs;
  int get shortlisted => _shortlisted;
  int get openJobs => _openJobs;
  String? get error => _error;

  List<Candidate> get topCandidates {
    final sorted = [..._candidates]
      ..sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
    return sorted.take(6).toList();
  }

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Your session has expired. Please log in again.');

      _candidates = await ApiService.getCandidates(token);
      _totalCVs = _candidates.length;
      _shortlisted = _candidates.where((c) => c.status == 'shortlisted').length;
      
      // Fetch jobs to show actual "Open Jobs" count
      final jobs = await ApiService.getJobs(token);
      _openJobs = jobs.length;
    } catch (e) {
      _error = ErrorMessage.from(e, fallback: 'Unable to sync dashboard data.');
    }

    _isLoading = false;
    notifyListeners();
  }
}

// ══════════════════════════════════════════════
//  UPLOAD VIEWMODEL
// ══════════════════════════════════════════════
class UploadViewModel extends ChangeNotifier {
  bool _isUploading = false;
  bool _isParsing = false;
  String? _error;
  Candidate? _parsedCandidate;
  final List<Map<String, String>> _files = [];

  bool get isUploading => _isUploading;
  bool get isParsing => _isParsing;
  String? get error => _error;
  Candidate? get parsedCandidate => _parsedCandidate;
  List<Map<String, String>> get files => _files;

  void loadFiles() {
    notifyListeners();
  }

  Future<Candidate?> pickAndParseResume() async {
    _error = null;
    _isUploading = true;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        _isUploading = false;
        notifyListeners();
        return null;
      }

      final pickedFile = result.files.first;
      var bytes = pickedFile.bytes;

      // Handle async cloud download race conditions
      if ((bytes == null || bytes.isEmpty) && pickedFile.path != null) {
        for (var attempt = 0; attempt < 8; attempt++) {
          try {
            final read = await File(pickedFile.path!).readAsBytes();
            if (read.isNotEmpty) { bytes = read; break; }
          } catch (_) {}
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Could not read the file. Please ensure it is fully downloaded to your device.');
      }

      _isParsing = true;
      notifyListeners();

      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Authentication failed. Please log in again.');

      _parsedCandidate = await ApiService.uploadResume(bytes, pickedFile.name, token);

      // COMMITTEE FIX: Sync local list immediately for better UX
      _files.insert(0, {
        'name': pickedFile.name,
        'type': pickedFile.extension?.toUpperCase() ?? 'PDF',
        'size': '${(bytes.length / 1024).toStringAsFixed(0)} KB',
        'time': 'Just now',
        'status': 'parsed',
      });

      _isUploading = false;
      _isParsing = false;
      notifyListeners();
      return _parsedCandidate;
    } catch (e) {
      _error = ErrorMessage.from(e, fallback: 'Resume parsing failed.');
      _isUploading = false;
      _isParsing = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

// ══════════════════════════════════════════════
//  CANDIDATES / SHORTLIST VIEWMODEL
// ══════════════════════════════════════════════
class CandidatesViewModel extends ChangeNotifier {
  bool _isLoading = false;
  List<Candidate> _all = [];
  String _filter = 'all';
  String? _loadError;

  bool get isLoading => _isLoading;
  String get filter => _filter;
  String? get loadError => _loadError;

  List<Candidate> get filtered {
    if (_filter == 'all') return _all;
    return _all.where((c) => c.status == _filter).toList();
  }

  Future<void> load() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Session expired.');
      _all = await ApiService.getCandidates(token);
    } catch (e) {
      _loadError = ErrorMessage.from(e, fallback: 'Unable to load candidates.');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFilter(String f) {
    _filter = f;
    notifyListeners();
  }

  Future<bool> updateStatus(Candidate candidate, String newStatus) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return false;

      await ApiService.updateCandidateStatus(candidate.id, newStatus, token);
      candidate.status = newStatus;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to update status: $e');
      return false;
    }
  }
}
