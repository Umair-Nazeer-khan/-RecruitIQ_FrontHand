// lib/viewmodels/job_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/error_message.dart';
import '../services/token_storage.dart';

class JobViewModel extends ChangeNotifier {
  // ── State ───────────────────────────────────
  List<JobRequirement> _jobs = [];
  bool _isLoading = false;
  bool _isMatching = false;
  bool _isSaving = false;
  MatchResult? _matchResult;
  String? _error;

  // ── Form fields (Private with Getters/Setters) ──
  String _title = '';
  String _department = '';
  String _location = 'Lahore';
  String _jobType = 'Full Time';
  int _minExperience = 2;
  String _educationLevel = 'BSc / BE';
  int _salaryMin = 80000;
  int _salaryMax = 150000;

  List<String> _requiredSkills = [];
  List<String> _optionalSkills = [];

  double _skillWeight = 0.5;
  double _experienceWeight = 0.3;
  double _educationWeight = 0.2;

  // ── Getters ──────────────────────────────────
  List<JobRequirement> get jobs => _jobs;
  bool get isLoading => _isLoading;
  bool get isMatching => _isMatching;
  bool get isSaving => _isSaving;
  MatchResult? get matchResult => _matchResult;
  String? get error => _error;

  String get title => _title;
  String get department => _department;
  String get location => _location;
  String get jobType => _jobType;
  int get minExperience => _minExperience;
  String get educationLevel => _educationLevel;
  int get salaryMin => _salaryMin;
  int get salaryMax => _salaryMax;
  List<String> get requiredSkills => _requiredSkills;
  List<String> get optionalSkills => _optionalSkills;
  double get skillWeight => _skillWeight;
  double get experienceWeight => _experienceWeight;
  double get educationWeight => _educationWeight;

  // ── Setters ──────────────────────────────────
  set title(String v) { _title = v; notifyListeners(); }
  set department(String v) { _department = v; notifyListeners(); }
  set location(String v) { _location = v; notifyListeners(); }
  set jobType(String v) { _jobType = v; notifyListeners(); }
  set educationLevel(String v) { _educationLevel = v; notifyListeners(); }
  set salaryMin(int v) { _salaryMin = v; notifyListeners(); }
  set salaryMax(int v) { _salaryMax = v; notifyListeners(); }

  // ── Initialization ──────────────────────────
  void resetForm() {
    _title = '';
    _department = '';
    _location = 'Lahore';
    _jobType = 'Full Time';
    _minExperience = 2;
    _educationLevel = 'BSc / BE';
    _salaryMin = 80000;
    _salaryMax = 150000;
    _requiredSkills = [];
    _optionalSkills = [];
    _skillWeight = 0.5;
    _experienceWeight = 0.3;
    _educationWeight = 0.2;
    _error = null;
    _matchResult = null;
    notifyListeners();
  }

  void setFromJob(JobRequirement job) {
    _title = job.title;
    _department = job.department;
    _location = job.location;
    _jobType = job.jobType;
    _minExperience = job.minExperience;
    _educationLevel = job.educationLevel;
    _salaryMin = job.salaryMin ?? 0;
    _salaryMax = job.salaryMax ?? 0;
    _requiredSkills = List.from(job.requiredSkills);
    _optionalSkills = List.from(job.optionalSkills);
    _skillWeight = job.skillWeight;
    _experienceWeight = job.experienceWeight;
    _educationWeight = job.educationWeight;
    notifyListeners();
  }

  // ── Job Management ──────────────────────────
  Future<void> loadJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Session expired');
      _jobs = await ApiService.getJobs(token);
    } catch (e) {
      _error = ErrorMessage.from(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveJob() async {
    if (!isValid) { _error = validationMessage; notifyListeners(); return false; }
    _isSaving = true; _error = null; notifyListeners();
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Session expired');
      final job = JobRequirement(
        title: _title, department: _department, location: _location, jobType: _jobType,
        requiredSkills: _requiredSkills, optionalSkills: _optionalSkills,
        minExperience: _minExperience, educationLevel: _educationLevel,
        salaryMin: _salaryMin, salaryMax: _salaryMax,
        skillWeight: _skillWeight, experienceWeight: _experienceWeight, educationWeight: _educationWeight,
      );
      await ApiService.createJob(job, token);
      await loadJobs();
      return true;
    } catch (e) {
      _error = ErrorMessage.from(e);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteJob(int id) async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) return;
      await ApiService.deleteJob(id, token);
      _jobs.removeWhere((j) => j.id == id);
      notifyListeners();
    } catch (e) {
      _error = ErrorMessage.from(e);
      notifyListeners();
    }
  }

  // ── Weight Management ──────────────────────
  void updateWeights({double? skill, double? exp, double? edu}) {
    if (skill != null) {
      _skillWeight = skill;
      final remaining = 1.0 - _skillWeight;
      final totalOther = _experienceWeight + _educationWeight;
      if (totalOther > 0) {
        _experienceWeight = (_experienceWeight / totalOther) * remaining;
        _educationWeight = (_educationWeight / totalOther) * remaining;
      } else {
        _experienceWeight = remaining / 2;
        _educationWeight = remaining / 2;
      }
    } else if (exp != null) {
      _experienceWeight = exp;
      final remaining = 1.0 - _experienceWeight;
      final totalOther = _skillWeight + _educationWeight;
      if (totalOther > 0) {
        _skillWeight = (_skillWeight / totalOther) * remaining;
        _educationWeight = (_educationWeight / totalOther) * remaining;
      } else {
        _skillWeight = remaining / 2;
        _educationWeight = remaining / 2;
      }
    } else if (edu != null) {
      _educationWeight = edu;
      final remaining = 1.0 - _educationWeight;
      final totalOther = _skillWeight + _experienceWeight;
      if (totalOther > 0) {
        _skillWeight = (_skillWeight / totalOther) * remaining;
        _experienceWeight = (_experienceWeight / totalOther) * remaining;
      } else {
        _skillWeight = remaining / 2;
        _experienceWeight = remaining / 2;
      }
    }

    _skillWeight = double.parse(_skillWeight.toStringAsFixed(2));
    _experienceWeight = double.parse(_experienceWeight.toStringAsFixed(2));
    _educationWeight = double.parse(_educationWeight.toStringAsFixed(2));
    
    final diff = 1.0 - (_skillWeight + _experienceWeight + _educationWeight);
    _skillWeight += diff;
    _skillWeight = double.parse(_skillWeight.toStringAsFixed(2));

    notifyListeners();
  }

  // ── Validation & Matching ──────────────────
  String? get validationMessage {
    if (_title.trim().isEmpty) return 'Job title is required.';
    if (_department.trim().isEmpty) return 'Department is required.';
    if (_requiredSkills.isEmpty) return 'Add at least one required skill.';
    if (_salaryMax < _salaryMin) return 'Max salary cannot be less than min.';
    return null;
  }

  bool get isValid => validationMessage == null;

  void addRequiredSkill(String s) { if (s.isNotEmpty && !_requiredSkills.contains(s)) { _requiredSkills.add(s); notifyListeners(); } }
  void removeRequiredSkill(String s) { _requiredSkills.remove(s); notifyListeners(); }
  void addOptionalSkill(String s) { if (s.isNotEmpty && !_optionalSkills.contains(s)) { _optionalSkills.add(s); notifyListeners(); } }
  void removeOptionalSkill(String s) { _optionalSkills.remove(s); notifyListeners(); }

  void incrementExp() { _minExperience++; notifyListeners(); }
  void decrementExp() { if (_minExperience > 0) { _minExperience--; notifyListeners(); } }

  Future<bool> findMatches({JobRequirement? existingJob}) async {
    _isMatching = true; _error = null; notifyListeners();
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Session expired');
      final job = existingJob ?? JobRequirement(
        title: _title, department: _department, location: _location, jobType: _jobType,
        requiredSkills: _requiredSkills, optionalSkills: _optionalSkills,
        minExperience: _minExperience, educationLevel: _educationLevel,
        salaryMin: _salaryMin, salaryMax: _salaryMax,
        skillWeight: _skillWeight, experienceWeight: _experienceWeight, educationWeight: _educationWeight,
      );
      _matchResult = await ApiService.matchCandidates(job, token);
      return true;
    } catch (e) {
      _error = ErrorMessage.from(e); return false;
    } finally {
      _isMatching = false; notifyListeners();
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}
