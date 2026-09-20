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

class CandidateDetailScreen extends StatefulWidget {
  final Candidate candidate;
  const CandidateDetailScreen({required this.candidate, super.key});

  @override
  State<CandidateDetailScreen> createState() => _CandidateDetailScreenState();
}

class _CandidateDetailScreenState extends State<CandidateDetailScreen> {
  bool _updating = false;
  bool _fetchingFresh = false;
  Candidate? _fullCandidate;

  @override
  void initState() {
    super.initState();
    _loadFreshDetail();
  }

  Future<void> _loadFreshDetail() async {
    setState(() => _fetchingFresh = true);
    try {
      final token = await TokenStorage.getAccessToken();
      if (token == null) throw Exception('Not authenticated');
      final fresh = await ApiService.getCandidateDetail(widget.candidate.id, token);
      if (!mounted) return;
      setState(() {
        _fullCandidate = fresh;
        _fetchingFresh = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _fetchingFresh = false);
    }
  }

  Candidate get candidate => _fullCandidate ?? widget.candidate;

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    final ok = await context.read<CandidatesViewModel>().updateStatus(candidate, status);
    if (!mounted) return;
    setState(() => _updating = false);
    if (ok) {
      ToastHelper.success(context, '${candidate.name} marked as ${status.toUpperCase()}');
    }
  }

  Future<void> _downloadResume() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null) return;
    final url = ApiService.getResumeDownloadUrl(candidate.id, token);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ToastHelper.error(context, 'Could not open download link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(children: [
        // ── Dark Hero Header ─────────────────
        Container(
          color: AppColors.ink,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1)),
                  ),
                  const SizedBox(width: 12),
                  Text('CANDIDATE DOSSIER', 
                    style: AppText.label(12, color: Colors.white.withValues(alpha: 0.5)).copyWith(letterSpacing: 0.08)),
                  const Spacer(),
                  if (_fetchingFresh)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24)),
                  const SizedBox(width: 12),
                  if (candidate.matchScore != null) ScorePill(candidate.matchScore!),
                ]),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(children: [
                  AvatarCircle(candidate.name, size: 64),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(candidate.name, style: AppText.headline(22, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(candidate.email, style: AppText.caption(13, color: Colors.white.withValues(alpha: 0.5))),
                    if (candidate.phone.isNotEmpty) 
                      Text(candidate.phone, style: AppText.caption(13, color: Colors.white.withValues(alpha: 0.5))),
                    if (candidate.location.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(children: [
                          Icon(Icons.location_on_outlined, size: 12, color: Colors.white.withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(candidate.location, style: AppText.caption(11, color: Colors.white.withValues(alpha: 0.4))),
                        ]),
                      ),
                  ])),
                ]),
              ),
            ]),
          ),
        ),

        // ── Main Content ─────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary & Education display boxes
              SectionCard(
                child: IntrinsicHeight(
                  child: Row(children: [
                    _InfoBox(label: 'EXPERIENCE', value: '${candidate.experienceYears.toStringAsFixed(0)} Years'),
                    const VerticalDivider(width: 32),
                    _InfoBox(label: 'EDUCATION', value: candidate.education.isNotEmpty ? candidate.education : (candidate.educationLevel.isNotEmpty ? candidate.educationLevel : 'N/A')),
                  ]),
                ),
              ),

              // AI Match Breakdown (Pinned Top Analysis if available)
              if (candidate.matchScore != null)
                SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const CardHeader(icon: Icons.analytics_rounded, iconBg: AppColors.purpleBg, iconColor: AppColors.purple, title: 'AI Match Analysis'),
                  const SizedBox(height: 12),
                  SkillMatchBar(label: 'Skills', value: (candidate.skillScore ?? 0) / 100, color: AppColors.accent, display: '${candidate.skillScore?.toInt() ?? 0}%'),
                  SkillMatchBar(label: 'Experience', value: (candidate.experienceScore ?? 0) / 100, color: AppColors.green, display: '${candidate.experienceScore?.toInt() ?? 0}%'),
                  SkillMatchBar(label: 'Education', value: (candidate.educationScore ?? 0) / 100, color: AppColors.orange, display: '${candidate.educationScore?.toInt() ?? 0}%'),
                  if (candidate.missingSkills != null && candidate.missingSkills!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('MISSING SKILLS', style: AppText.label(10, color: AppColors.red).copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: candidate.missingSkills!.map((s) => SkillTag(s, required: false)).toList()),
                  ],
                  if (candidate.scoreExplanation != null) Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(candidate.scoreExplanation!, style: AppText.caption(12, color: AppColors.ink3)),
                  ),
                ])),

              if (candidate.summary.isNotEmpty)
                _ExpandableSection(
                  title: 'Professional Summary',
                  icon: Icons.person_search_rounded,
                  iconBg: AppColors.scoreHighBg,
                  iconColor: AppColors.green,
                  itemCount: 1, previewCount: 1,
                  builder: (_) => Text(candidate.summary, style: AppText.body(13)),
                ),

              // Dynamic loop for ALL technical skill categories
              if (candidate.technicalSkills.isNotEmpty)
                _ExpandableSection(
                  title: 'Technical Skills',
                  icon: Icons.code_rounded,
                  iconBg: AppColors.accent.withValues(alpha: 0.1),
                  iconColor: AppColors.accent,
                  itemCount: candidate.technicalSkills.length,
                  previewCount: 3,
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

              // Dynamic loop for ALL soft skills
              if (candidate.softSkills.isNotEmpty)
                _ExpandableSection(
                  title: 'Soft Skills',
                  icon: Icons.psychology_outlined,
                  iconBg: AppColors.purpleBg,
                  iconColor: AppColors.purple,
                  itemCount: candidate.softSkills.length,
                  previewCount: 10,
                  builder: (count) => Wrap(
                    spacing: 6, runSpacing: 6,
                    children: candidate.softSkills.take(count).map((s) => SkillTag(s, required: false)).toList(),
                  ),
                ),

              // Dynamic loop for ALL work experience jobs & bullet points
              _ExpandableSection(
                title: 'Career History',
                icon: Icons.work_history_rounded,
                iconBg: AppColors.scoreHighBg,
                iconColor: AppColors.green,
                itemCount: candidate.workHistory.length,
                previewCount: 2,
                emptyText: 'No experience records found.',
                builder: (count) => Column(
                  children: candidate.workHistory.take(count).toList().asMap().entries.map((e) {
                    return _ExpRow(exp: e.value, isLast: e.key == count - 1);
                  }).toList(),
                ),
              ),

              // Dynamic loop for ALL education entries
              if (candidate.educationHistory.isNotEmpty)
                _ExpandableSection(
                  title: 'Education',
                  icon: Icons.school_rounded,
                  iconBg: AppColors.scoreMidBg,
                  iconColor: AppColors.amber,
                  itemCount: candidate.educationHistory.length,
                  previewCount: 2,
                  builder: (count) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: candidate.educationHistory.take(count).map((edu) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(edu.degree, style: AppText.label(13).copyWith(fontWeight: FontWeight.bold)),
                        Text('${edu.institution} · ${edu.duration}', style: AppText.caption(12)),
                      ]),
                    )).toList(),
                  ),
                ),

              // Dynamic loop for ALL projects
              if (candidate.projects.isNotEmpty)
                _ExpandableSection(
                  title: 'Portfolio Projects',
                  icon: Icons.folder_special_rounded,
                  iconBg: AppColors.purpleBg,
                  iconColor: AppColors.purple,
                  itemCount: candidate.projects.length,
                  previewCount: 2,
                  builder: (count) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: candidate.projects.take(count).map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, style: AppText.label(13).copyWith(fontWeight: FontWeight.bold)),
                        if (p.description.isNotEmpty) 
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(p.description, style: AppText.caption(12, color: AppColors.ink3)),
                          ),
                        if (p.techStack.isNotEmpty) Padding(
                          padding: const EdgeInsets.only(top: 8),
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

              // ALL certifications
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

              // ALL awards
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

              // ALL languages
              if (candidate.languages.isNotEmpty)
                SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const CardHeader(icon: Icons.language_rounded, iconBg: AppColors.scoreHighBg, iconColor: AppColors.green, title: 'Languages'),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 6, children: candidate.languages.map((l) => SkillTag(l, required: false)).toList()),
                ])),

              // ALL additional information
              if (candidate.additionalInfo != null && candidate.additionalInfo!.isNotEmpty)
                SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const CardHeader(icon: Icons.info_outline, iconBg: AppColors.purpleBg, iconColor: AppColors.purple, title: 'Additional Information'),
                  const SizedBox(height: 10),
                  Text(candidate.additionalInfo!, style: AppText.body(12)),
                ])),

              const SizedBox(height: 24),

              // ── Action Buttons ──────────────────
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => _updateStatus('rejected'), 
                  icon: const Icon(Icons.close_rounded, color: AppColors.red, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: FilledButton.icon(
                  onPressed: () => _updateStatus('accepted'), 
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Hire Candidate'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _downloadResume, 
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download Original CV'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton(
                  onPressed: (candidate.status == 'shortlisted' || _updating) ? null : () => _updateStatus('shortlisted'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _updating 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : Text(candidate.status == 'shortlisted' ? 'Shortlisted ✓' : 'Shortlist')
                )),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ]),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label, value;
  const _InfoBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: AppText.caption(9).copyWith(letterSpacing: 1, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(value, style: AppText.label(14).copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
  ]));
}

class _ExpRow extends StatelessWidget {
  final WorkExperience exp;
  final bool isLast;
  const _ExpRow({required this.exp, required this.isLast});
  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: BoxDecoration(shape: BoxShape.circle, color: isLast ? AppColors.green : AppColors.accent)),
            if (!isLast) Expanded(child: Container(width: 1, margin: const EdgeInsets.only(top: 4), color: AppColors.border2)),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exp.company, style: AppText.label(13).copyWith(fontWeight: FontWeight.bold)),
            Text('${exp.role} · ${exp.duration}', style: AppText.caption(11)),
            if (exp.bullets.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...exp.bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(top: 6), child: Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.ink3))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(b, style: AppText.caption(11, color: AppColors.ink2))),
                ]),
              )),
            ],
          ])),
        ]),
      ),
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
      if (widget.itemCount == 0 && widget.emptyText != null) 
        Text(widget.emptyText!, style: AppText.caption(12, color: AppColors.ink3)) 
      else 
        widget.builder(visibleCount),
      if (hasOverflow) ...[
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(children: [
            Text(_expanded ? 'Show Less' : 'Show More (${widget.itemCount - widget.previewCount} more)', style: AppText.label(12, color: AppColors.accent)),
            const SizedBox(width: 4), 
            Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.accent)
          ]),
        ),
      ],
    ]));
  }
}
