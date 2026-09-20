// lib/views/screens/shortlist_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../../utils/toast_helper.dart';
import '../../models/models.dart';
import '../widgets/shared_widgets.dart';
import 'candidate_detail_screen.dart';

class ShortlistScreen extends StatefulWidget {
  const ShortlistScreen({super.key});
  @override
  State<ShortlistScreen> createState() => _ShortlistScreenState();
}

class _ShortlistScreenState extends State<ShortlistScreen> {
  int _tabIndex = 0;
  final _tabs = ['Pending', 'Shortlisted', 'Accepted', 'Rejected', 'On Hold'];
  final _statuses = ['pending', 'shortlisted', 'accepted', 'rejected', 'on_hold'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CandidatesViewModel>().load();
    });
  }

  Future<void> _exportCsv(BuildContext context) async {
    final vm = context.read<CandidatesViewModel>();
    final list = vm.filtered;

    if (list.isEmpty) {
      ToastHelper.info(context, 'No candidates to export in this tab');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Name,Email,Phone,Experience (yrs),Education,Location,Status,Match Score,Skills');
    for (final c in list) {
      final row = [
        c.name, c.email, c.phone, c.experienceYears.toStringAsFixed(1),
        c.education, c.location, c.status,
        c.matchScore?.toStringAsFixed(0) ?? '',
        c.skills.join('; '),
      ].map((f) => '"${f.replaceAll('"', '""')}"').join(',');
      buffer.writeln(row);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    ToastHelper.success(context, '${list.length} candidates copied to clipboard (CSV)');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        title: 'Talent Pipeline',
        showBack: false,
        actions: [
          IconButton(
            onPressed: () => _exportCsv(context),
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            tooltip: 'Export List',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        // ── Status Filter Tabs ──────────────────
        Container(
          color: AppColors.cardBg,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(_tabs.length, (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_tabs[i]),
                  selected: _tabIndex == i,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _tabIndex = i);
                      context.read<CandidatesViewModel>().setFilter(_statuses[i]);
                    }
                  },
                  selectedColor: AppColors.ink,
                  labelStyle: TextStyle(
                    color: _tabIndex == i ? Colors.white : AppColors.ink2,
                    fontSize: 12, fontWeight: FontWeight.bold
                  ),
                ),
              )),
            ),
          ),
        ),
        const Divider(height: 1),

        // ── List ──────────────────────────────
        Expanded(
          child: Consumer<CandidatesViewModel>(builder: (_, vm, __) {
            if (vm.isLoading) return const Center(child: CircularProgressIndicator());
            
            if (vm.loadError != null) {
              return StandardErrorView(message: vm.loadError!, onRetry: vm.load);
            }

            final list = vm.filtered;
            if (list.isEmpty) {
              return StandardEmptyView(
                title: 'No candidates found',
                subtitle: 'Candidates in the ${_tabs[_tabIndex]} stage will appear here.',
                icon: Icons.person_search_rounded,
              );
            }

            return RefreshIndicator(
              onRefresh: () => vm.load(),
              color: AppColors.accent,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (_, i) => _ShortlistCard(candidate: list[i], vm: vm),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

class _ShortlistCard extends StatelessWidget {
  final Candidate candidate;
  final CandidatesViewModel vm;
  const _ShortlistCard({required this.candidate, required this.vm});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AvatarCircle(candidate.name, size: 48),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(candidate.name, style: AppText.title(15), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${candidate.experienceYears.toStringAsFixed(0)}y Exp · ${candidate.education}', 
                style: AppText.caption(11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          if (candidate.matchScore != null) ScorePill(candidate.matchScore!),
        ]),
        
        if (candidate.skills.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 6, runSpacing: 6, children: candidate.skills.take(4).map((s) => SkillTag(s, required: false)).toList()),
        ],

        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CandidateDetailScreen(candidate: candidate))),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('View Profile'),
          )),
          const SizedBox(width: 8),
          if (candidate.status != 'accepted') 
            _ActionIconBtn(icon: Icons.check_circle_outline_rounded, color: AppColors.green, onTap: () => _update(context, 'accepted')),
          if (candidate.status != 'on_hold')
            _ActionIconBtn(icon: Icons.pause_circle_outline_rounded, color: Colors.blueAccent, onTap: () => _update(context, 'on_hold')),
          if (candidate.status != 'rejected')
            _ActionIconBtn(icon: Icons.highlight_off_rounded, color: AppColors.red, onTap: () => _update(context, 'rejected')),
          if (candidate.status != 'pending')
            _ActionIconBtn(icon: Icons.history_rounded, color: AppColors.ink3, onTap: () => _update(context, 'pending')),
        ]),
      ]),
    );
  }

  Future<void> _update(BuildContext context, String status) async {
    final ok = await vm.updateStatus(candidate, status);
    if (context.mounted && ok) {
      ToastHelper.success(context, '${candidate.name} is now ${status.replaceAll("_", " ").toUpperCase()}');
    }
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _ActionIconBtn({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 6),
    child: IconButton.filled(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );
}
