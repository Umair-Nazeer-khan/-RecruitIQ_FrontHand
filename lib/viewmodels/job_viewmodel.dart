// lib/viewmodels/job_viewmodel.dart
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../utils/error_message.dart';
import '../services/token_storage.dart';

class JobViewModel extends ChangeNotifier {
  // ── Form fields ─────────────────────────────
  String title = 'Senior Flutter Developer';
  String department = 'Engineering';
  String location = 'Lahore';
  String jobType = 'Full Time';
  int minExperience = 3;
  String education = 'BSc / BE';
  int salaryMin = 80000;
  int salaryMax = 150000;

  List<String> requiredSkills = ['Flutter', 'Dart', 'REST API', 'Git', 'Firebase'];
  List<String> optionalSkills = ['Python', 'Docker', 'CI/CD'];

  double skillWeight = 0.5;
  double experienceWeight = 0.3;
  double educationWeight = 0.2;

  bool _isMatching = false;
  MatchResult? _matchResult;
  String? _error;

  bool get isMatching => _isMatching;
  MatchResult? get matchResult => _matchResult;
  String? get error => _error;

  // ── Validation Logic ────────────────────────
  String? get validationMessage {
    if (title.trim().isEmpty) return 'Job title is required.';
    if (department.trim().isEmpty) return 'Department is required.';
    if (requiredSkills.isEmpty) return 'Please add at least one required skill for the AI to match.';
    if (salaryMax < salaryMin) return 'Maximum salary cannot be less than minimum.';
    return null;
  }

  bool get isValid => validationMessage == null;

  // ── Skill management ────────────────────────
  void addRequiredSkill(String skill) {
    if (skill.isNotEmpty && !requiredSkills.contains(skill)) {
      requiredSkills.add(skill);
      notifyListeners();
    }
  }

  void removeRequiredSkill(String skill) {
    requiredSkills.remove(skill);
    notifyListeners();
  }

  void addOptionalSkill(String skill) {
    if (skill.isNotEmpty && !optionalSkills.contains(skill)) {
      optionalSkills.add(skill);
      notifyListeners();
    }
  }

  void removeOptionalSkill(String skill) {
    optionalSkills.remove(skill);
    notifyListeners();
  }

  // ── Experience stepper ─────────────────────
  void incrementExp() { minExperience++; notifyListeners(); }
  void decrementExp() { if (minExperience > 0) { minExperience--; notifyListeners(); } }

  // ── Weight sliders ──────────────────────────
  void setSkillWeight(double v) {
    skillWeight = v;
    // Auto-normalize so all 3 weights always sum to 1.0 (Professional AI Logic)
    final remaining = 1.0 - v;
    experienceWeight = double.parse((remaining * 0.6).toStringAsFixed(2));
    educationWeight = double.parse((remaining * 0.4).toStringAsFixed(2));
    notifyListeners();
  }

  // ── Find Matching Candidates ─────────────────
  Future<bool> findMatches() async {
    if (!isValid) {
      _error = validationMessage;
      notifyListeners();
      return false;
    }

    _isMatching = true;
    _error = null;
    notifyListeners();

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Your session has expired. Please log in.');

      final job = JobRequirement(
        title: title,
        department: department,
        location: location,
        jobType: jobType,
        requiredSkills: requiredSkills,
        optionalSkills: optionalSkills,
        minExperience: minExperience,
        educationLevel: education,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        skillWeight: skillWeight,
        experienceWeight: experienceWeight,
        educationWeight: educationWeight,
      );

      _matchResult = await ApiService.matchCandidates(job, token);
      _isMatching = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorMessage.from(e, fallback: 'Matching failed. Please try again.');
      _isMatching = false;
      notifyListeners();
      return false;
    }
  }
}
