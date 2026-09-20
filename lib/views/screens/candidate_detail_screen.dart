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

  Future<void> _loadFreshDetail() async {
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Not authenticated');
      final fresh = await ApiService.getCandidateDetail(widget.candidate.id, token);
      if (!mounted) return;
      setState(() {
        _fullCandidate = fresh;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _fullCandidate = widget.candidate;
        _loading = false;
      });
    }
  }

  Candidate get candidate => _fullCandidate ?? widget.candidate;

  Future<void> _shortlist(BuildContext context) async {
    setState(() => _updating = true);
    await context.read<CandidatesViewModel>().updateStatus(candidate, 'shortlisted');
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('CANDIDATE PROFILE', style: AppText.label(12, color: Colors.white.withValues(alpha: 0.5)).copyWith(letterSpacing: 0.08)),
                ]),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(children: [
                  Row(children: [
                    AvatarCircle(candidate.name, size: 52),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(candidate.name, style: AppText.headline(18, color: Colors.white)),
                      const SizedBox(height: 3),
                      Text('${candidate.email} · ${candidate.phone}', style: AppText.caption(12, color: Colors.white.withValues(alpha: 0.45))),
                    ])),
                  ]),
                  const SizedBox(height: 14),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    _WhiteChip('${candidate.experienceYears.toStringAsFixed(0)}y Experience'),
                    if (candidate.location.isNotEmpty) _WhiteChip(candidate.location),
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
              // Summary Section
              if (candidate.summary.isNotEmpty)
                SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const CardHeader(icon: Icons.person_search_rounded, iconBg: AppColors.scoreHighBg, iconColor: AppColors.green, title: 'Professional Summary'),
                  const SizedBox(height: 10),
                  Text(candidate.summary, style: AppText.body(13)),
                ])),

              // Technical Skills (Categorized)
              if (candidate.technicalSkills.isNotEmpty)
                _ExpandableSection(
                  title: 'Technical Skills',
                  icon: Icons.code_rounded,
                  iconBg: AppColors.accent.withValues(alpha: 0.1),
                  iconColor: AppColors.accent,
                  itemCount: candidate.technicalSkills.length,
                  previewCount: 2,
                  builder: (count) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: candidate.technicalSkills.entries.take(count).map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(entry.key.toUpperCase(), style: AppText.label(10, color: AppColors.ink3).copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Wrap(spacing: 6, runSpacing: 6, children: entry.value.map((s) => SkillTag(s, required: false)).toList()),
                      ]),
                    )).toList(),
                  ),
                ),

              // Work Experience
              _ExpandableSection(
                title: 'Work Experience',
                icon: Icons.work_history_rounded,
                iconBg: AppColors.scoreHighBg,
                iconColor: AppColors.green,
                itemCount: candidate.workHistory.length,
                previewCount: 2,
                emptyText: 'No experience details extracted.',
                builder: (count) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: candidate.workHistory.take(count).toList().asMap().entries.map((e) {
                    return _ExpRow(exp: e.value, isLast: e.key == count - 1);
                  }).toList(),
                ),
              ),

              // Education entries
              if (candidate.educationHistory.isNotEmpty)
                _ExpandableSection(
                  title: 'Education history',
                  icon: Icons.school_rounded,
                  iconBg: AppColors.scoreMidBg,
                  iconColor: AppColors.amber,
                  itemCount: candidate.educationHistory.length,
                  previewCount: 2,
                  builder: (count) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: candidate.educationHistory.take(count).map((edu) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(edu.degree, style: AppText.label(13)),
                        Text('${edu.institution} · ${edu.duration}', style: AppText.caption(11)),
                      ]),
                    )).toList(),
                  ),
                ),

              // Projects
              if (candidate.projects.isNotEmpty)
                _ExpandableSection(
                  title: 'Key Projects',
                  icon: Icons.folder_special_rounded,
                  iconBg: AppColors.purpleBg,
                  iconColor: AppColors.purple,
                  itemCount: candidate.projects.length,
                  previewCount: 2,
                  builder: (count) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: candidate.projects.take(count).map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: AppText.label(14)),
                        if (p.description.isNotEmpty) Text(p.description, style: AppText.caption(12, color: AppColors.ink3)),
                        if (p.techStack.isNotEmpty) Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(spacing: 4, runSpacing: 4, children: p.techStack.map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.border2)),
                            child: Text(t, style: AppText.caption(9)),
                          )).toList()),
                        ),
                      ]),
                    )).toList(),
                  ),
                ),

              // Certifications & Awards
              if (candidate.certifications.isNotEmpty)
                _ExpandableSection(
                  title: 'Certifications',
                  icon: Icons.verified_rounded,
                  iconBg: AppColors.scoreHighBg,
                  iconColor: AppColors.green,
                  itemCount: candidate.certifications.length,
                  previewCount: 3,
                  builder: (count) => Column(children: candidate.certifications.take(count).map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [const Icon(Icons.check_circle_outline, size: 14, color: AppColors.green), const SizedBox(width: 8), Expanded(child: Text(c, style: AppText.body(12)))]),
                  )).toList()),
                ),

              if (candidate.awards.isNotEmpty)
                _ExpandableSection(
                  title: 'Awards & Honors',
                  icon: Icons.emoji_events_rounded,
                  iconBg: AppColors.scoreMidBg,
                  iconColor: AppColors.amber,
                  itemCount: candidate.awards.length,
                  previewCount: 3,
                  builder: (count) => Column(children: candidate.awards.take(count).map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [const Icon(Icons.star_outline_rounded, size: 14, color: AppColors.amber), const SizedBox(width: 8), Expanded(child: Text(a, style: AppText.body(12)))]),
                  )).toList()),
                ),

              // Languages
              if (candidate.languages.isNotEmpty)
                SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const CardHeader(icon: Icons.language_rounded, iconBg: AppColors.scoreHighBg, iconColor: AppColors.green, title: 'Languages'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: candidate.languages.map((l) => SkillTag(l, required: false)).toList()),
                ])),

              // Additional Info
              if (candidate.additionalInfo != null && candidate.additionalInfo!.isNotEmpty)
                SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const CardHeader(icon: Icons.info_outline, iconBg: AppColors.purpleBg, iconColor: AppColors.purple, title: 'Additional Information'),
                  const SizedBox(height: 10),
                  Text(candidate.additionalInfo!, style: AppText.body(12)),
                ])),

              // Score Breakdown (AI Only)
              if (candidate.matchScore != null)
                SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const CardHeader(icon: Icons.analytics_rounded, iconBg: AppColors.purpleBg, iconColor: AppColors.purple, title: 'AI Match Analysis'),
                  const SizedBox(height: 12),
                  SkillMatchBar(label: 'Skills', value: (candidate.skillScore ?? 0) / 100, color: AppColors.accent, display: '${candidate.skillScore?.toInt() ?? 0}%'),
                  SkillMatchBar(label: 'Experience', value: (candidate.experienceScore ?? 0) / 100, color: AppColors.green, display: '${candidate.experienceYears.toStringAsFixed(0)}yr'),
                  if (candidate.scoreExplanation != null) Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(candidate.scoreExplanation!, style: AppText.caption(12, color: AppColors.ink3)),
                  ),
                ])),

              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => _viewCv(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text('View Original CV', style: AppText.title(13)))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: (candidate.status == 'shortlisted' || _updating) ? null : () => _shortlist(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _updating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(candidate.status == 'shortlisted' ? 'Shortlisted ✓' : 'Shortlist Candidate', style: AppText.title(13)))),
              ]),
              const SizedBox(height: 20),
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
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppText.body(11, color: Colors.white.withValues(alpha: 0.7))));
}

class _ExpRow extends StatelessWidget {
  final WorkExperience exp;
  final bool isLast;
  const _ExpRow({required this.exp, required this.isLast});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(shape: BoxShape.circle, color: isLast ? AppColors.green : AppColors.accent)),
          if (!isLast) Expanded(child: Container(width: 1, margin: const EdgeInsets.only(top: 4), color: AppColors.border2)),
        ]),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exp.company, style: AppText.label(13)),
          Text('${exp.role} · ${exp.duration}', style: AppText.caption(11)),
          if (exp.bullets.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...exp.bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 6), child: Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.ink3))),
                const SizedBox(width: 8),
                Expanded(child: Text(b, style: AppText.caption(11, color: AppColors.ink2))),
              ]),
            )),
          ],
        ])),
      ]),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconBg, iconColor;
  final int itemCount;
  final int previewCount;
  final Widget Function(int visibleCount) builder;
  final String? emptyText;
  const _ExpandableSection({required this.title, required this.icon, required this.iconBg, required this.iconColor, required this.itemCount, required this.previewCount, required this.builder, this.emptyText});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final hasOverflow = widget.itemCount > widget.previewCount;
    final visibleCount = _expanded ? widget.itemCount : widget.previewCount;

    return SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CardHeader(icon: widget.icon, iconBg: widget.iconBg, iconColor: widget.iconColor, title: widget.title),
      const SizedBox(height: 10),
      if (widget.itemCount == 0 && widget.emptyText != null) Text(widget.emptyText!, style: AppText.caption(12, color: AppColors.ink3)) else widget.builder(visibleCount),
      if (hasOverflow) ...[
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(children: [Text(_expanded ? 'Show Less' : 'Show More (${widget.itemCount - widget.previewCount} more)', style: AppText.label(12, color: AppColors.accent)), const SizedBox(width: 4), Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.accent)]),
        ),
      ],
    ]));
  }
}
