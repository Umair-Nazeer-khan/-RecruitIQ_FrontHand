// lib/views/screens/match_results_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../../utils/toast_helper.dart';
import '../../models/models.dart';
import '../widgets/shared_widgets.dart';
import 'candidate_detail_screen.dart';

class MatchResultsScreen extends StatefulWidget {
  const MatchResultsScreen({super.key});
  @override
  State<MatchResultsScreen> createState() => _MatchResultsScreenState();
}

class _MatchResultsScreenState extends State<MatchResultsScreen> {
  String _filter = 'all'; // 'all' | '80' | '60'

  List<Candidate> _filtered(List<Candidate> all) {
    if (_filter == '80')
      return all.where((c) => (c.matchScore ?? 0) >= 80).toList();
    if (_filter == '60')
      return all
          .where((c) => (c.matchScore ?? 0) >= 60 && (c.matchScore ?? 0) < 80)
          .toList();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JobViewModel>();
    final result = vm.matchResult;
    if (result == null) return const SizedBox.shrink();

    final candidates = _filtered(result.rankedCandidates);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(children: [
        // ── Dark summary header ─────────────
        Container(
          color: AppColors.ink,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width > 600
                        ? 600.0
                        : double.infinity),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm)),
                                  child: const Icon(Icons.arrow_back_ios_new,
                                      color: Colors.white, size: 14))),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                              child: Text('MATCH RESULTS',
                                  style: AppText.label(12,
                                          color: Colors.white.withOpacity(0.5))
                                      .copyWith(letterSpacing: 0.08))),
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: AppColors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('AI Complete',
                                  style: AppText.label(11,
                                      color: AppColors.green))),
                        ]),
                        const SizedBox(height: AppSpace.md),
                        Text(vm.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.headline(16, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                            '${vm.department} · ${vm.jobType} · '
                            '${vm.location} · ${vm.minExperience}+ yrs exp',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption(12,
                                color: Colors.white.withOpacity(0.4))),
                        const SizedBox(height: AppSpace.md),
                        Row(children: [
                          _StatChip(
                              value: result.totalScanned.toString(),
                              label: 'CVs scanned',
                              color: Colors.white),
                          const SizedBox(width: AppSpace.sm),
                          _StatChip(
                              value: result.goodMatch.toString(),
                              label: 'Good match',
                              color: AppColors.green),
                          const SizedBox(width: AppSpace.sm),
                          _StatChip(
                              value: result.partialMatch.toString(),
                              label: 'Partial',
                              color: AppColors.amber),
                          const SizedBox(width: AppSpace.sm),
                          _StatChip(
                              value: result.noMatch.toString(),
                              label: 'No match',
                              color: AppColors.red),
                        ]),
                      ]),
                ),
              ),
            ),
          ),
        ),

        // ── Filter chips ────────────────────
        Container(
          color: AppColors.cardBg,
          padding: const EdgeInsets.fromLTRB(
              AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width > 600
                      ? 600.0
                      : double.infinity),
              child: Row(children: [
                _FilterChip(
                    label: 'All (${result.rankedCandidates.length})',
                    active: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 6),
                _FilterChip(
                    label:
                        '80%+ (${result.rankedCandidates.where((c) => (c.matchScore ?? 0) >= 80).length})',
                    active: _filter == '80',
                    onTap: () => setState(() => _filter = '80')),
                const SizedBox(width: 6),
                _FilterChip(
                    label:
                        '60–79% (${result.rankedCandidates.where((c) => (c.matchScore ?? 0) >= 60 && (c.matchScore ?? 0) < 80).length})',
                    active: _filter == '60',
                    onTap: () => setState(() => _filter = '60')),
              ]),
            ),
          ),
        ),
        Container(height: 1, color: AppColors.border),

        // ── Candidate list ──────────────────
        Expanded(
          child: candidates.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.filter_alt_off_rounded,
                          size: 40, color: AppColors.ink3),
                      const SizedBox(height: AppSpace.sm),
                      Text('No candidates in this range',
                          style: AppText.body(13, color: AppColors.ink3)),
                    ]),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width > 600
                            ? 600.0
                            : double.infinity),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpace.md),
                      itemCount: candidates.length,
                      itemBuilder: (_, i) => _MatchCard(
                        candidate: candidates[i],
                        rank: i + 1,
                      ),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

// ── Match candidate card ─────────────────────
class _MatchCard extends StatelessWidget {
  final Candidate candidate;
  final int rank;
  const _MatchCard({required this.candidate, required this.rank});

  @override
  Widget build(BuildContext context) {
    final score = candidate.matchScore ?? 0;
    final isTop = rank == 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isTop
            ? Border.all(color: AppColors.accent.withOpacity(0.2), width: 1.5)
            : Border.all(color: AppColors.border),
        boxShadow: [
          const BoxShadow(
              color: Color(0x0A0A1F1D), blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top row
        Row(children: [
          // Rank badge
          Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                  color: isTop
                      ? AppColors.accent.withOpacity(0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(7)),
              child: Center(
                  child: Text('#$rank',
                      style: AppText.label(11,
                          color: isTop ? AppColors.accent : AppColors.ink3)))),
          const SizedBox(width: 8),
          AvatarCircle(candidate.name),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(candidate.name,
                    style: AppText.title(14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                    '${candidate.experienceYears} yrs · '
                    '${candidate.education} · ${candidate.location}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption(11)),
              ])),
          Text('${score.toInt()}%',
              style: AppText.headline(22, color: scoreColor(score))),
        ]),
        const SizedBox(height: 10),

        // Score bars
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

        // Missing skills warning
        if (candidate.missingSkills != null &&
            candidate.missingSkills!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: AppColors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('⚠  Missing: ${candidate.missingSkills!.join(', ')}',
                  style: AppText.body(11, color: AppColors.red))),
        ],

        // Action buttons
        const SizedBox(height: 10),
        Row(children: [
          _ActionBtn(
              label: 'View CV',
              bg: AppColors.accent.withOpacity(0.08),
              fg: AppColors.accent,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CandidateDetailScreen(candidate: candidate)))),
          const SizedBox(width: 6),
          _ActionBtn(
              label: 'Shortlist',
              bg: AppColors.green.withOpacity(0.1),
              fg: AppColors.scoreHighFg,
              onTap: () async {
                final ok = await context
                    .read<CandidatesViewModel>()
                    .updateStatus(candidate, 'shortlisted');
                if (context.mounted) {
                  if (ok) {
                    ToastHelper.success(
                        context, '${candidate.name} shortlisted');
                  } else {
                    ToastHelper.error(context,
                        'Could not shortlist ${candidate.name}. Please try again.');
                  }
                }
              }),
          const SizedBox(width: 6),
          _ActionBtn(
              label: 'Reject',
              bg: AppColors.scoreLowBg,
              fg: AppColors.scoreLowFg,
              onTap: () async {
                final ok = await context
                    .read<CandidatesViewModel>()
                    .updateStatus(candidate, 'rejected');
                if (context.mounted) {
                  if (ok) {
                    ToastHelper.info(context, '${candidate.name} rejected');
                  } else {
                    ToastHelper.error(context,
                        'Could not reject ${candidate.name}. Please try again.');
                  }
                }
              }),
        ]),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color bg, fg;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.bg,
      required this.fg,
      required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
      child: GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(9)),
              child: Center(
                  child: Text(label, style: AppText.label(11, color: fg))))));
}

class _StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatChip(
      {required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text(value, style: AppText.headline(20, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    AppText.caption(10, color: Colors.white.withOpacity(0.4))),
          ])));
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: active ? AppColors.ink : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: active ? null : Border.all(color: AppColors.border2)),
          child: Text(label,
              style: AppText.label(11,
                  color: active ? Colors.white : AppColors.ink2))));
}
