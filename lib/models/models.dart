// lib/models/models.dart
// ─────────────────────────────────────────────────────────────
//  All data models — match the Django backend JSON exactly.
// ─────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ══════════════════════════════════════════════
//  USER MODEL
// ══════════════════════════════════════════════
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? fcmToken;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['id']?.toString() ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'hr_manager',
      fcmToken: json['fcm_token'],
      createdAt: json['created_at'] is Timestamp
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'fcm_token': fcmToken,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromFirestore(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? 'hr_manager',
      fcmToken: json['fcm_token'],
      createdAt: json['created_at'] is Timestamp
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }
}

// ══════════════════════════════════════════════
//  WORK EXPERIENCE MODEL
// ══════════════════════════════════════════════
class WorkExperience {
  final String company;
  final String role;
  final String duration;
  final String? description;

  WorkExperience({
    required this.company,
    required this.role,
    required this.duration,
    this.description,
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      company: json['company'] ?? json['details'] ?? '',
      role: json['role'] ?? '',
      duration: json['duration'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'company': company,
      'role': role,
      'duration': duration,
      'description': description,
    };
  }
}

// ══════════════════════════════════════════════
//  PROJECT MODEL
// ══════════════════════════════════════════════
class ProjectItem {
  final String name;
  final String description;

  ProjectItem({required this.name, required this.description});

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

// ══════════════════════════════════════════════
//  CANDIDATE MODEL
//  Matches Django CandidateSerializer exactly
// ══════════════════════════════════════════════
class Candidate {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final double experienceYears;
  final String education;
  final String educationLevel;
  final List<String> skills;
  final List<String> languages;
  final List<ProjectItem> projects;
  final List<WorkExperience> workHistory;
  final String originalName;
  final String? resumeFileUrl;
  double? matchScore;
  double? skillScore;
  double? experienceScore;
  double? educationScore;
  List<String>? missingSkills;
  String? scoreExplanation;
  String status;
  String? hrNotes;
  final DateTime createdAt;

  Candidate({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
    required this.experienceYears,
    required this.education,
    required this.educationLevel,
    required this.skills,
    this.languages = const [],
    this.projects = const [],
    required this.workHistory,
    required this.originalName,
    this.resumeFileUrl,
    this.matchScore,
    this.skillScore,
    this.experienceScore,
    this.educationScore,
    this.missingSkills,
    this.scoreExplanation,
    this.status = 'pending',
    this.hrNotes,
    required this.createdAt,
  });

  // ── Convert backend JSON → Dart object ─────────────────────
  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      experienceYears: (json['experience_years'] as num?)?.toDouble() ?? 0,
      education: json['education'] ?? '',
      educationLevel: json['education_level'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      projects: (json['projects'] as List? ?? [])
          .map((e) => ProjectItem.fromJson(e))
          .toList(),
      workHistory: (json['work_history'] as List? ?? [])
          .map((e) => WorkExperience.fromJson(e))
          .toList(),
      originalName: json['original_name'] ?? '',
      resumeFileUrl: json['resume_file_url'],
      matchScore: (json['match_score'] as num?)?.toDouble(),
      skillScore: (json['skill_score'] as num?)?.toDouble(),
      experienceScore: (json['experience_score'] as num?)?.toDouble(),
      educationScore: (json['education_score'] as num?)?.toDouble(),
      missingSkills: json['missing_skills'] != null
          ? List<String>.from(json['missing_skills'])
          : null,
      scoreExplanation: json['score_explanation'],
      status: json['status'] ?? 'pending',
      hrNotes: json['hr_notes'],
      createdAt: json['created_at'] is Timestamp
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  // ── Convert from /matching/match/ result format ────────────
  // (slightly different field names than CandidateSerializer)
  factory Candidate.fromMatchResult(Map<String, dynamic> json) {
    return Candidate(
      id: json['candidate_id'] ?? 0,
      name: json['candidate_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      experienceYears: (json['experience_years'] as num?)?.toDouble() ?? 0,
      education: '',
      educationLevel: json['education_level'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      workHistory: [],
      originalName: '',
      matchScore: (json['final_score'] as num?)?.toDouble(),
      skillScore: (json['skill_score'] as num?)?.toDouble(),
      experienceScore: (json['experience_score'] as num?)?.toDouble(),
      educationScore: (json['education_score'] as num?)?.toDouble(),
      missingSkills: json['missing_skills'] != null
          ? List<String>.from(json['missing_skills'])
          : null,
      scoreExplanation: json['explanation'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
      'experience_years': experienceYears,
      'education': education,
      'education_level': educationLevel,
      'skills': skills,
      'work_history': workHistory.map((e) => e.toJson()).toList(),
      'original_name': originalName,
      'match_score': matchScore,
      'skill_score': skillScore,
      'experience_score': experienceScore,
      'education_score': educationScore,
      'missing_skills': missingSkills,
      'score_explanation': scoreExplanation,
      'status': status,
      'hr_notes': hrNotes,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}

// ══════════════════════════════════════════════
//  JOB MODEL
// ══════════════════════════════════════════════
class JobRequirement {
  final int? id;
  final String title;
  final String department;
  final String location;
  final String jobType;
  final List<String> requiredSkills;
  final List<String> optionalSkills;
  final int minExperience;
  final String educationLevel;
  final int? salaryMin;
  final int? salaryMax;
  final double skillWeight;
  final double experienceWeight;
  final double educationWeight;

  JobRequirement({
    this.id,
    required this.title,
    required this.department,
    required this.location,
    required this.jobType,
    required this.requiredSkills,
    required this.optionalSkills,
    required this.minExperience,
    required this.educationLevel,
    this.salaryMin,
    this.salaryMax,
    this.skillWeight = 0.5,
    this.experienceWeight = 0.3,
    this.educationWeight = 0.2,
  });

  // ── For POST /matching/match/  (uses job_type as snake_case key names) ──
  Map<String, dynamic> toMatchJson() => {
        if (id != null) 'job_id': id,
        'title': title,
        'department': department,
        'location': location,
        'job_type': jobType,
        'required_skills': requiredSkills,
        'optional_skills': optionalSkills,
        'min_experience': minExperience,
        'education_level': educationLevel,
        'salary_min': salaryMin,
        'salary_max': salaryMax,
        'skill_weight': skillWeight,
        'experience_weight': experienceWeight,
        'education_weight': educationWeight,
      };

  // ── For POST /jobs/  (create job posting) ──
  Map<String, dynamic> toJson() => toMatchJson();

  factory JobRequirement.fromJson(Map<String, dynamic> json) {
    return JobRequirement(
      id: json['id'],
      title: json['title'] ?? '',
      department: json['department'] ?? '',
      location: json['location'] ?? '',
      jobType: json['job_type'] ?? 'full_time',
      requiredSkills: List<String>.from(json['required_skills'] ?? []),
      optionalSkills: List<String>.from(json['optional_skills'] ?? []),
      minExperience: json['min_experience'] ?? 0,
      educationLevel: json['education_level'] ?? 'BSc / BE',
      salaryMin: json['salary_min'],
      salaryMax: json['salary_max'],
      skillWeight: (json['skill_weight'] as num?)?.toDouble() ?? 0.5,
      experienceWeight: (json['experience_weight'] as num?)?.toDouble() ?? 0.3,
      educationWeight: (json['education_weight'] as num?)?.toDouble() ?? 0.2,
    );
  }
}

// ══════════════════════════════════════════════
//  MATCH RESULT MODEL
// ══════════════════════════════════════════════
class MatchResult {
  final int totalScanned;
  final int goodMatch;
  final int partialMatch;
  final int noMatch;
  final List<Candidate> rankedCandidates;

  MatchResult({
    required this.totalScanned,
    required this.goodMatch,
    required this.partialMatch,
    required this.noMatch,
    required this.rankedCandidates,
  });

  // ── Matches the exact response from POST /matching/match/ ──
  factory MatchResult.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? {};
    final List results = json['results'] ?? [];
    return MatchResult(
      totalScanned: stats['total'] ?? 0,
      goodMatch: stats['good_match'] ?? 0,
      partialMatch: stats['partial'] ?? 0,
      noMatch: stats['no_match'] ?? 0,
      rankedCandidates:
          results.map((e) => Candidate.fromMatchResult(e)).toList(),
    );
  }
}
