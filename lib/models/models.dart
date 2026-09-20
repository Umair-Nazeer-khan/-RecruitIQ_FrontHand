// lib/models/models.dart
import 'package:cloud_firestore/cloud_firestore.dart';

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
}

class WorkExperience {
  final String company;
  final String role;
  final String duration;
  final String? description;
  final List<String> bullets;

  WorkExperience({
    required this.company,
    required this.role,
    required this.duration,
    this.description,
    this.bullets = const [],
  });

  factory WorkExperience.fromJson(Map<String, dynamic> json) {
    return WorkExperience(
      company: json['company'] ?? json['details'] ?? json['organization'] ?? '',
      role: json['role'] ?? json['designation'] ?? json['title'] ?? '',
      duration: json['duration'] ?? json['period'] ?? json['date_range'] ?? '',
      description: json['description'] ?? json['summary'],
      bullets: List<String>.from(json['bullets'] ??
          json['bullet_points'] ??
          json['responsibilities'] ??
          []),
    );
  }

  Map<String, dynamic> toJson() => {
        'company': company,
        'role': role,
        'duration': duration,
        'description': description,
        'bullets': bullets,
      };
}

class ProjectItem {
  final String name;
  final String description;
  final List<String> techStack;

  ProjectItem({
    required this.name,
    required this.description,
    this.techStack = const [],
  });

  factory ProjectItem.fromJson(Map<String, dynamic> json) {
    return ProjectItem(
      name: json['name'] ?? json['title'] ?? '',
      description: json['description'] ?? '',
      techStack: List<String>.from(
          json['tech_stack'] ?? json['technologies'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'tech_stack': techStack,
      };
}

class EducationItem {
  final String institution;
  final String degree;
  final String duration;

  EducationItem({
    required this.institution,
    required this.degree,
    required this.duration,
  });

  factory EducationItem.fromJson(Map<String, dynamic> json) {
    return EducationItem(
      institution: json['institution'] ?? json['school'] ?? json['university'] ?? '',
      degree: json['degree'] ?? json['education'] ?? json['qualification'] ?? '',
      duration: json['duration'] ?? json['period'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'institution': institution,
        'degree': degree,
        'duration': duration,
      };
}

class Candidate {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String location;
  final double experienceYears;
  final String summary;
  final String education; // Display string
  final String educationLevel;
  final List<EducationItem> educationHistory;
  final List<String> skills; // Fallback
  final Map<String, List<String>> technicalSkills;
  final List<String> softSkills;
  final List<String> languages;
  final List<ProjectItem> projects;
  final List<WorkExperience> workHistory;
  final List<String> certifications;
  final List<String> awards;
  final String? additionalInfo;
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
    this.summary = '',
    this.education = '',
    this.educationLevel = '',
    this.educationHistory = const [],
    this.skills = const [],
    this.technicalSkills = const {},
    this.softSkills = const [],
    this.languages = const [],
    this.projects = const [],
    this.workHistory = const [],
    this.certifications = const [],
    this.awards = const [],
    this.additionalInfo,
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

  factory Candidate.fromJson(Map<String, dynamic> json) {
    final techMap = <String, List<String>>{};
    if (json['technical_skills'] is Map) {
      (json['technical_skills'] as Map).forEach((key, value) {
        techMap[key.toString()] = List<String>.from(value is List ? value : []);
      });
    } else if (json['skills'] is List) {
      techMap['Skills'] = List<String>.from(json['skills']);
    }

    final eduList = (json['education_history'] ?? json['education'] ?? []) as List;
    final workList = (json['work_experience'] ?? json['work_history'] ?? []) as List;

    String eduStr = json['education'] is String ? json['education'] : '';
    if (eduStr.isEmpty && eduList.isNotEmpty) {
      final first = EducationItem.fromJson(eduList.first is Map ? eduList.first as Map<String, dynamic> : {});
      eduStr = '${first.degree} @ ${first.institution}';
    }

    return Candidate(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      location: json['location'] ?? '',
      experienceYears: (json['experience_years'] as num?)?.toDouble() ?? 0,
      summary: json['summary'] ?? json['objective'] ?? '',
      education: eduStr,
      educationLevel: json['education_level'] ?? '',
      educationHistory: eduList.map((e) => EducationItem.fromJson(e)).toList(),
      skills: List<String>.from(json['skills'] ?? []),
      technicalSkills: techMap,
      softSkills: List<String>.from(json['soft_skills'] ?? []),
      languages: List<String>.from(json['languages'] ?? []),
      projects: (json['projects'] as List? ?? []).map((e) => ProjectItem.fromJson(e)).toList(),
      workHistory: workList.map((e) => WorkExperience.fromJson(e)).toList(),
      certifications: List<String>.from(json['certifications'] ?? []),
      awards: List<String>.from(json['awards'] ?? []),
      additionalInfo: json['additional_information']?.toString() ?? json['additional_info']?.toString(),
      originalName: json['original_name'] ?? '',
      resumeFileUrl: json['resume_file_url'],
      matchScore: (json['match_score'] as num?)?.toDouble() ?? (json['final_score'] as num?)?.toDouble(),
      skillScore: (json['skill_score'] as num?)?.toDouble(),
      experienceScore: (json['experience_score'] as num?)?.toDouble(),
      educationScore: (json['education_score'] as num?)?.toDouble(),
      missingSkills: json['missing_skills'] != null ? List<String>.from(json['missing_skills']) : null,
      scoreExplanation: json['score_explanation'] ?? json['explanation'],
      status: json['status'] ?? 'pending',
      hrNotes: json['hr_notes'],
      createdAt: json['created_at'] is Timestamp
          ? (json['created_at'] as Timestamp).toDate()
          : DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  factory Candidate.fromMatchResult(Map<String, dynamic> json) {
    return Candidate.fromJson({
      ...json,
      if (json.containsKey('candidate_id')) 'id': json['candidate_id'],
      if (json.containsKey('candidate_name')) 'name': json['candidate_name'],
    });
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'location': location,
        'status': status,
        'created_at': Timestamp.fromDate(createdAt),
      };
}

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
