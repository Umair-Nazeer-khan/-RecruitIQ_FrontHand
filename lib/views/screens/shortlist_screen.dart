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
  final _tabs = ['Pending', 'Shortlisted', 'Accepted', 'Rejected'];
  final _statuses = ['pending', 'shortlisted', 'accepted', 'rejected'];

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
        c.name, c.email, c.phone, c.experienceYears.toString(),
        c.education, c.location, c.status,
        c.matchScore?.toStringAsFixed(0) ?? '',
        c.skills.join('; '),
      ].map((f) => '"${f.replaceAll('"', '""')}"').join(',');
      buffer.writeln(row);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    ToastHelper.success(context, '${list.length} candidates copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        title: 'Talent Shortlist',
        showBack: false,
        actions: [
          IconButton(
            onPressed: () => _exportCsv(context),
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: 'Export List',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        // ── Navigation Tabs ────────────────────
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
                    fontSize: 12, fontWeight: FontWeight.w600
                  ),
                ),
              )),
            ),
          ),
        ),
        const Divider(height: 1),

        // ── List Content ───────────────────────
        Expanded(
          child: Consumer<CandidatesViewModel>(builder: (_, vm, __) {
            if (vm.isLoading) return const Center(child: CircularProgressIndicator());
            
            if (vm.loadError != null) {
              return StandardErrorView(message: vm.loadError!, onRetry: vm.load);
            }

            final list = vm.filtered;
            if (list.isEmpty) {
              return StandardEmptyView(
                title: 'No ${_tabs[_tabIndex]} candidates',
                subtitle: 'Candidates moved to the ${_tabs[_tabIndex].toLowerCase()} stage will appear here.',
                icon: Icons.group_off_rounded,
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
          AvatarCircle(candidate.name, size: 44),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(candidate.name, style: AppText.title(15), maxLines: 1),
            Text('${candidate.experienceYears.toStringAsFixed(0)}y Exp • ${candidate.educationLevel}', 
                style: AppText.caption(11)),
          ])),
          if (candidate.matchScore != null) ScorePill(candidate.matchScore!),
        ]),
        const SizedBox(height: 16),
        Wrap(spacing: 6, runSpacing: 6, children: candidate.skills.take(3).map((s) => SkillTag(s, required: false)).toList()),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CandidateDetailScreen(candidate: candidate))),
            child: const Text('Details'),
          )),
          const SizedBox(width: 10),
          if (candidate.status == 'pending' || candidate.status == 'shortlisted') ...[
            _SmallActionBtn(label: 'Accept', color: AppColors.green, onTap: () => _update(context, 'accepted')),
            const SizedBox(width: 8),
            _SmallActionBtn(label: 'Reject', color: AppColors.red, onTap: () => _update(context, 'rejected')),
          ] else
            _SmallActionBtn(label: 'Reset to Pending', color: AppColors.ink2, onTap: () => _update(context, 'pending')),
        ]),
      ]),
    );
  }

  Future<void> _update(BuildContext context, String status) async {
    final ok = await vm.updateStatus(candidate, status);
    if (context.mounted && ok) {
      ToastHelper.success(context, '${candidate.name} is now ${status.toUpperCase()}');
    }
  }
}

class _SmallActionBtn extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _SmallActionBtn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: color.withOpacity(.1),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(.2)),
        elevation: 0,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 42),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ),
  );
}
