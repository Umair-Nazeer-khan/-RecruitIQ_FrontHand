// lib/views/screens/candidate_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/token_storage.dart';
import '../../utils/app_constants.dart';
import '../../utils/toast_helper.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../widgets/shared_widgets.dart';
import 'job_requirements_screen.dart';

class CandidateDetailScreen extends StatefulWidget {
  final Candidate candidate;
  const CandidateDetailScreen({required this.candidate, super.key});

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  bool _updating = false;
  bool _loading = true;
  Candidate? _fullCandidate;

  @override
  void initState() {
    super.initState();
    _loadFreshDetail();
  }

  // Always fetch the complete, up-to-date candidate record from the
  // server rather than trusting whatever partial object (e.g. from a
  // compact list) was passed in when navigating here.
  Future<void> _loadFreshDetail() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Not authenticated');
      final fresh =
          await ApiService.getCandidateDetail(widget.candidate.id, token);
      if (!mounted) return;
      setState(() {
        _fullCandidate = fresh;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Fall back to whatever we were passed if the fresh fetch fails
      // (e.g. offline) rather than showing a blank screen.
      setState(() {
        _fullCandidate = widget.candidate;
        _loading = false;
      });
    }
  }

  Candidate get candidate => _fullCandidate ?? widget.candidate;

  Future<void> _shortlist(BuildContext context) async {
    setState(() => _updating = true);
    await context
        .read<CandidatesViewModel>()
        .updateStatus(candidate, 'shortlisted');
    if (!mounted) return;
    setState(() => _updating = false);
    ToastHelper.success(context, '${candidate.name} added to shortlist');
  }

  Future<void> _viewCv(BuildContext context) async {
    final url = candidate.resumeFileUrl;
    if (url == null || url.isEmpty) {
      ToastHelper.error(context, 'Original resume file is not available.');
      return;
    }
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ToastHelper.error(context, 'Could not open the resume file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(children: [
        // ── Dark hero header ─────────────────
        Container(
          color: AppColors.ink,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              // Back row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('PARSED RESULT',
                      style: AppText.label(12,
                              color: Colors.white.withOpacity(0.5))
                          .copyWith(letterSpacing: 0.08)),
                ]),
              ),

              // Candidate info
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(children: [
                  Row(children: [
                    AvatarCircle(candidate.name, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(candidate.name,
                              style: AppText.headline(18, color: Colors.white)),
                          const SizedBox(height: 3),
                          Text('${candidate.email} · ${candidate.phone}',
                              style: AppText.caption(12,
                                  color: Colors.white.withOpacity(0.45))),
                        ])),
                  ]),
                  const SizedBox(height: 14),
                  // Chips
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _WhiteChip('${candidate.experienceYears} yrs experience'),
                    _WhiteChip(candidate.education),
                    _WhiteChip(candidate.location),
                  ]),
                ]),
              ),
            ]),
          ),
        ),

        // ── Body ─────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Skills
              SectionCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    CardHeader(
                        icon: Icons.code_rounded,
                        iconBg: AppColors.accent.withOpacity(0.1),
                        iconColor: AppColors.accent,
                        title: 'Extracted Skills'),
                    const SizedBox(height: 10),
                    Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: candidate.skills
                            .map((s) => SkillTag(s, required: false))
                            .toList()),
                  ])),

              // Work Experience
              SectionCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const CardHeader(
                        icon: Icons.work_history_rounded,
                        iconBg: AppColors.scoreHighBg,
                        iconColor: AppColors.green,
                        title: 'Work Experience'),
                    const SizedBox(height: 10),
                    if (candidate.workHistory.isEmpty)
                      Text('No work experience extracted from this resume.',
                          style: AppText.caption(12, color: AppColors.ink3))
                    else
                      ...candidate.workHistory.asMap().entries.map((e) {
                        final isLast =
                            e.key == candidate.workHistory.length - 1;
                        return _ExpRow(exp: e.value, isLast: isLast);
                      }),
                  ])),

              // Education
              SectionCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const CardHeader(
                        icon: Icons.school_rounded,
                        iconBg: AppColors.scoreMidBg,
                        iconColor: AppColors.amber,
                        title: 'Education'),
                    const SizedBox(height: 10),
                    Text(
                        candidate.education.isNotEmpty
                            ? candidate.education
                            : 'No education details extracted from this resume.',
                        style: candidate.education.isNotEmpty
                            ? AppText.label(14)
                            : AppText.caption(12, color: AppColors.ink3)),
                  ])),

              // Languages
              if (candidate.languages.isNotEmpty)
                SectionCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const CardHeader(
                          icon: Icons.language_rounded,
                          iconBg: AppColors.scoreHighBg,
                          iconColor: AppColors.green,
                          title: 'Languages'),
                      const SizedBox(height: 10),
                      Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: candidate.languages
                              .map((l) => SkillTag(l, required: false))
                              .toList()),
                    ])),

              // Projects
              if (candidate.projects.isNotEmpty)
                SectionCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const CardHeader(
                          icon: Icons.folder_special_rounded,
                          iconBg: AppColors.purpleBg,
                          iconColor: AppColors.purple,
                          title: 'Projects'),
                      const SizedBox(height: 10),
                      ...candidate.projects.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, style: AppText.label(14)),
                                  if (p.description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(p.description,
                                          style: AppText.caption(12,
                                              color: AppColors.ink3)),
                                    ),
                                ]),
                          )),
                    ])),

              // Score breakdown (if available)
              if (candidate.matchScore != null)
                SectionCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const CardHeader(
                          icon: Icons.analytics_rounded,
                          iconBg: AppColors.purpleBg,
                          iconColor: AppColors.purple,
                          title: 'AI Match Score'),
                      const SizedBox(height: 12),
                      SkillMatchBar(
                          label: 'Skills',
                          value: (candidate.skillScore ?? 0) / 100,
                          color: AppColors.accent,
                          display: candidate.skillScore != null
                              ? '${candidate.skillScore!.toInt()}%'
                              : '—'),
                      SkillMatchBar(
                          label: 'Experience',
                          value: (candidate.experienceScore ?? 0) / 100,
                          color: AppColors.green,
                          display: '${candidate.experienceYears}yr'),
                      SkillMatchBar(
                          label: 'Education',
                          value: (candidate.educationScore ?? 0) / 100,
                          color: AppColors.amber,
                          display: candidate.educationScore != null
                              ? '${candidate.educationScore!.toInt()}%'
                              : '—'),
                    ])),

              // Action buttons
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                  onPressed: () => _viewCv(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.border2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('View CV', style: AppText.title(13)),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: ElevatedButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const JobRequirementsScreen())),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('Match',
                      style: AppText.title(13, color: Colors.white)),
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: OutlinedButton(
                  onPressed: (_updating || candidate.status == 'shortlisted')
                      ? null
                      : () => _shortlist(context),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.border2),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: _updating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(
                          candidate.status == 'shortlisted'
                              ? 'Shortlisted ✓'
                              : 'Shortlist',
                          style: AppText.title(12)),
                )),
              ]),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ]),
    );
  }
}

class _WhiteChip extends StatelessWidget {
  final String label;
  const _WhiteChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: AppText.body(11, color: Colors.white.withOpacity(0.7))));
}

class _ExpRow extends StatelessWidget {
  final WorkExperience exp;
  final bool isLast;
  const _ExpRow({required this.exp, required this.isLast});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLast ? AppColors.green : AppColors.accent)),
          if (!isLast)
            Container(width: 1, height: 28, color: AppColors.border2),
        ]),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exp.company, style: AppText.label(13)),
          Text('${exp.role} · ${exp.duration}', style: AppText.caption(11)),
        ])),
      ]),
    );
  }
}
