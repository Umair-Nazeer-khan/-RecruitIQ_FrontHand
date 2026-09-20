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
  String _filter = 'all'; 

  List<Candidate> _filtered(List<Candidate> all) {
    if (_filter == '80') return all.where((c) => (c.matchScore ?? 0) >= 80).toList();
    if (_filter == '60') return all.where((c) => (c.matchScore ?? 0) >= 60 && (c.matchScore ?? 0) < 80).toList();
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JobViewModel>();
    final result = vm.matchResult;
    
    if (result == null) {
      return Scaffold(
        body: StandardErrorView(
          message: 'No match results found.', 
          onRetry: () => Navigator.maybePop(context),
        ),
      );
    }

    final candidates = _filtered(result.rankedCandidates);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        title: 'AI Ranking',
        actions: [
          IconButton(
            onPressed: () => ToastHelper.info(context, 'Ranking based on your custom weights.'),
            icon: const Icon(Icons.info_outline_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        // ── Summary Header ───────────────────
        Container(
          color: AppColors.ink,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(vm.title, style: AppText.headline(20, color: Colors.white)),
            const SizedBox(height: 4),
            Text('${result.totalScanned} candidates analyzed by AI', 
                style: AppText.caption(12, color: Colors.white60)),
            const SizedBox(height: 20),
            Row(children: [
              _SummaryPill(count: result.goodMatch, label: 'Good', color: AppColors.green),
              const SizedBox(width: 8),
              _SummaryPill(count: result.partialMatch, label: 'Partial', color: AppColors.amber),
              const SizedBox(width: 8),
              _SummaryPill(count: result.noMatch, label: 'Poor', color: AppColors.red),
            ]),
          ]),
        ),

        // ── Filters ──────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(children: [
            _TabChip(label: 'All (${result.rankedCandidates.length})', active: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
            _TabChip(label: '80%+', active: _filter == '80', onTap: () => setState(() => _filter = '80')),
            _TabChip(label: '60-79%', active: _filter == '60', onTap: () => setState(() => _filter = '60')),
          ]),
        ),
        const Divider(height: 1),

        // ── List ──────────────────────────────
        Expanded(
          child: candidates.isEmpty
            ? const StandardEmptyView(title: 'No matches found', subtitle: 'Try adjusting your required skills or experience weights.')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: candidates.length,
                itemBuilder: (_, i) => _MatchCard(candidate: candidates[i], rank: i + 1),
              ),
        ),
      ]),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Candidate candidate;
  final int rank;
  const _MatchCard({required this.candidate, required this.rank});

  @override
  Widget build(BuildContext context) {
    final score = candidate.matchScore ?? 0;
    return SectionCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('#$rank', style: AppText.label(12, color: AppColors.accent))),
          ),
          const SizedBox(width: 10),
          AvatarCircle(candidate.name, size: 40),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(candidate.name, style: AppText.title(14), maxLines: 1),
            Text('${candidate.experienceYears.toStringAsFixed(0)}y · ${candidate.location}', style: AppText.caption(10)),
          ])),
          ScorePill(score),
        ]),
        const SizedBox(height: 16),
        
        SkillMatchBar(label: 'Skills', value: (candidate.skillScore ?? 0)/100, color: AppColors.accent, display: '${candidate.skillScore?.toInt() ?? 0}%'),
        SkillMatchBar(label: 'Experience', value: (candidate.experienceScore ?? 0)/100, color: AppColors.green, display: '${candidate.experienceScore?.toInt() ?? 0}%'),
        
        if (candidate.missingSkills != null && candidate.missingSkills!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.05), 
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.red),
              const SizedBox(width: 8),
              Expanded(child: Text('Missing: ${candidate.missingSkills!.join(", ")}', style: AppText.caption(11, color: AppColors.red))),
            ]),
          ),
        ],

        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CandidateDetailScreen(candidate: candidate))), child: const Text('View Profile'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton(onPressed: () => _shortlist(context), child: const Text('Shortlist'))),
        ]),
      ]),
    );
  }

  Future<void> _shortlist(BuildContext context) async {
    final ok = await context.read<CandidatesViewModel>().updateStatus(candidate, 'shortlisted');
    if (context.mounted && ok) ToastHelper.success(context, '${candidate.name} added to shortlist');
  }
}

class _SummaryPill extends StatelessWidget {
  final int count; final String label; final Color color;
  const _SummaryPill({required this.count, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(count.toString(), style: AppText.headline(18, color: color)),
        Text(label, style: AppText.caption(9, color: Colors.white38)),
      ]),
    ),
  );
}

class _TabChip extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _TabChip({required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label), selected: active, onSelected: (_) => onTap(),
      selectedColor: AppColors.ink,
      labelStyle: TextStyle(color: active ? Colors.white : AppColors.ink2, fontSize: 12),
    ),
  );
}
