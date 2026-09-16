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
    return sorted.take(4).toList();
  }

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Not authenticated');

      _candidates = await ApiService.getCandidates(token);
      _totalCVs = _candidates.length;
      _shortlisted = _candidates.where((c) => c.status == 'shortlisted').length;
      _openJobs =
          0; // TODO: wire to a real "open jobs count" endpoint when available
    } catch (e) {
      debugPrint('Failed to load dashboard: $e');
      _error = ErrorMessage.from(e,
          fallback: 'Could not load dashboard. Please try again.');
    }

    _isLoading = false;
    notifyListeners();
  }
}

// ══════════════════════════════════════════════
//  UPLOAD VIEWMODEL
//  file_picker 8.x API — uses PlatformFile
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
    // No dedicated "uploaded files" backend endpoint yet.
    // This list is populated as files are picked/parsed during this session.
    notifyListeners();
  }

  Future<Candidate?> pickAndParseResume() async {
    _error = null;
    _isUploading = true;
    notifyListeners();

    try {
      // Step 1: Pick file — load bytes directly so this works reliably
      // for cloud-backed sources (e.g. Google Drive) where the returned
      // path can be unreadable or point to 0 bytes.
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

      // Step 2: Get file bytes — try the direct bytes first, then read
      // from the cached path, retrying briefly if it comes back empty.
      // This handles a known file_picker race condition with cloud
      // sources (e.g. Google Drive): Android copies the remote file into
      // a local cache file asynchronously, and if we read it too early
      // we get a 0-byte placeholder before the download finishes.
      final pickedFile = result.files.first;
      var bytes = pickedFile.bytes;

      if ((bytes == null || bytes.isEmpty) && pickedFile.path != null) {
        for (var attempt = 0; attempt < 12; attempt++) {
          try {
            final read = await File(pickedFile.path!).readAsBytes();
            if (read.isNotEmpty) {
              bytes = read;
              break;
            }
          } catch (_) {
            // keep retrying until attempts run out
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (bytes == null || bytes.isEmpty) {
        _error = 'Could not read the selected file — it may still be '
            'downloading from a cloud source. Please save it to your '
            'phone\'s local storage first, then try picking it again.';
        _isUploading = false;
        notifyListeners();
        return null;
      }

      // Step 3: Parse with AI via backend
      _isParsing = true;
      notifyListeners();

      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Not authenticated');

      _parsedCandidate =
          await ApiService.uploadResume(bytes, pickedFile.name, token);

      _isUploading = false;
      _isParsing = false;
      notifyListeners();
      return _parsedCandidate;
    } catch (e) {
      _error = ErrorMessage.from(e,
          fallback: 'Resume could not be processed. Please try again.');
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

  int countByStatus(String status) =>
      _all.where((c) => c.status == status).length;

  Future<void> load() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Not authenticated');
      _all = await ApiService.getCandidates(token);
    } catch (e) {
      debugPrint('Failed to load candidates: $e');
      _loadError = ErrorMessage.from(e,
          fallback: 'Could not load candidates. Please try again.');
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
      if (token == null) throw Exception('Not authenticated');

      await ApiService.updateCandidateStatus(candidate.id, newStatus, token);
      // NOTE: FirebaseService().updateCandidateStatus(...) is also available
      // if you want statuses mirrored to Firebase as well — not called here
      // since FastAPI is currently the single source of truth.
      candidate.status = newStatus;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to update status: $e');
      _loadError = ErrorMessage.from(e,
          fallback: 'Candidate status could not be updated. Please try again.');
      notifyListeners();
      return false;
    }
  }
}
