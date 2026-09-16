// lib/viewmodels/job_viewmodel.dart

import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/error_message.dart';
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

  List<String> requiredSkills = [
    'Flutter',
    'Dart',
    'REST API',
    'Git',
    'Firebase'
  ];
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
  void incrementExp() {
    minExperience++;
    notifyListeners();
  }

  void decrementExp() {
    if (minExperience > 0) {
      minExperience--;
      notifyListeners();
    }
  }

  // ── Weight sliders ──────────────────────────
  void setSkillWeight(double v) {
    skillWeight = v;
    // normalize so all 3 always sum to 1.0
    final remaining = 1.0 - v;
    experienceWeight = double.parse((remaining * 0.6).toStringAsFixed(2));
    educationWeight = double.parse((remaining * 0.4).toStringAsFixed(2));
    notifyListeners();
  }

  // ── Find Matching Candidates ─────────────────
  Future<void> findMatches() async {
    _isMatching = true;
    _error = null;
    notifyListeners();

    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Not authenticated');

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
    } catch (e) {
      _error =
          ErrorMessage.from(e, fallback: 'Matching failed. Please try again.');
    }

    _isMatching = false;
    notifyListeners();
  }
}
