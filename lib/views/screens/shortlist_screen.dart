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
    buffer.writeln('Name,Email,Phone,Experience (yrs),Education,Location,'
        'Status,Match Score,Skills');
    for (final c in list) {
      final row = [
        c.name,
        c.email,
        c.phone,
        c.experienceYears.toString(),
        c.education,
        c.location,
        c.status,
        c.matchScore?.toStringAsFixed(0) ?? '',
        c.skills.join('; '),
      ].map((f) => '"${f.replaceAll('"', '""')}"').join(',');
      buffer.writeln(row);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!context.mounted) return;
    ToastHelper.success(context,
        '${list.length} candidates copied — paste into Excel or Sheets');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(children: [
        // ── Header ────────────────────────────
        Container(
          color: AppColors.cardBg,
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(children: [
                  Expanded(
                      child: Text('Shortlist', style: AppText.headline(20))),
                  GestureDetector(
                      onTap: () => _exportCsv(context),
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border2)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.download_rounded,
                                size: 14, color: AppColors.ink2),
                            const SizedBox(width: 4),
                            Text('Export CSV', style: AppText.label(12)),
                          ]))),
                ]),
              ),

              // Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                    children: List.generate(
                        _tabs.length,
                        (i) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _tabIndex = i);
                                context
                                    .read<CandidatesViewModel>()
                                    .setFilter(_statuses[i]);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                    color: _tabIndex == i
                                        ? AppColors.ink
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: _tabIndex != i
                                        ? Border.all(color: AppColors.border2)
                                        : null),
                                child: Text(_tabs[i],
                                    style: AppText.label(12,
                                        color: _tabIndex == i
                                            ? Colors.white
                                            : AppColors.ink2)),
                              ),
                            )))),
              ),
            ]),
          ),
        ),
        Container(height: 1, color: AppColors.border),

        // ── List ──────────────────────────────
        Expanded(
          child: Consumer<CandidatesViewModel>(builder: (_, vm, __) {
            if (vm.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent));
            }
            final list = vm.filtered;
            if (list.isEmpty) {
              return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.inbox_rounded,
                    size: 48, color: AppColors.ink3),
                const SizedBox(height: 10),
                Text('No candidates here yet',
                    style: AppText.body(14, color: AppColors.ink3)),
              ]));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: list.length,
              itemBuilder: (_, i) => _ShortlistCard(candidate: list[i], vm: vm),
            );
          }),
        ),
      ]),
    );
  }
}

// ── Shortlist card ───────────────────────────
class _ShortlistCard extends StatelessWidget {
  final Candidate candidate;
  final CandidatesViewModel vm;
  const _ShortlistCard({required this.candidate, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppDecor.card(radius: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top row
        Row(children: [
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
                const SizedBox(height: 2),
                Text(
                    '${candidate.experienceYears} yrs · ${candidate.education}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption(11)),
              ])),
          if (candidate.matchScore != null)
            Text('${candidate.matchScore!.toInt()}%',
                style: AppText.headline(18,
                    color: scoreColor(candidate.matchScore!))),
        ]),
        const SizedBox(height: 10),

        // Skills
        Wrap(
            spacing: 5,
            runSpacing: 5,
            children: candidate.skills
                .take(4)
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(5)),
                      child: Text(s, style: AppText.caption(10)),
                    ))
                .toList()),
        const SizedBox(height: 10),

        // Action buttons
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
              label: 'Accept',
              bg: AppColors.scoreHighBg,
              fg: AppColors.scoreHighFg,
              onTap: () async {
                final ok = await vm.updateStatus(candidate, 'accepted');
                if (context.mounted) {
                  ToastHelper.show(
                      context,
                      ok
                          ? '${candidate.name} marked as accepted.'
                          : 'Could not update ${candidate.name}.',
                      type: ok ? ToastType.success : ToastType.error);
                }
              }),
          const SizedBox(width: 6),
          _ActionBtn(
              label: 'Hold',
              bg: AppColors.surface,
              fg: AppColors.ink2,
              onTap: () async {
                final ok = await vm.updateStatus(candidate, 'shortlisted');
                if (context.mounted) {
                  ToastHelper.show(
                      context,
                      ok
                          ? '${candidate.name} shortlisted.'
                          : 'Could not update ${candidate.name}.',
                      type: ok ? ToastType.success : ToastType.error);
                }
              }),
          const SizedBox(width: 6),
          _ActionBtn(
              label: 'Reject',
              bg: AppColors.scoreLowBg,
              fg: AppColors.scoreLowFg,
              onTap: () async {
                final ok = await vm.updateStatus(candidate, 'rejected');
                if (context.mounted) {
                  ToastHelper.show(
                      context,
                      ok
                          ? '${candidate.name} rejected.'
                          : 'Could not update ${candidate.name}.',
                      type: ok ? ToastType.info : ToastType.error);
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(9)),
              child: Center(
                  child: Text(label, style: AppText.label(11, color: fg))))));
}
