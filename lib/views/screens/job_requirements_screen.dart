// lib/views/screens/job_requirements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../widgets/shared_widgets.dart';
import 'match_results_screen.dart';

class JobRequirementsScreen extends StatelessWidget {
  const JobRequirementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _JobForm();
  }
}

class _JobForm extends StatefulWidget {
  const _JobForm();
  @override
  State<_JobForm> createState() => _JobFormState();
}

class _JobFormState extends State<_JobForm> {
  final _skillCtrl = TextEditingController();
  final _optSkillCtrl = TextEditingController();

  final List<String> _jobTypes = [
    'Full Time',
    'Part Time',
    'Remote',
    'Contract'
  ];
  final List<String> _eduLevels = [
    'Matric',
    'Intermediate',
    'BSc / BE',
    'MSc / MS',
    'PhD'
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JobViewModel>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        title: 'Post a Job',
        showBack: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20)),
            child: Text('Step 1 of 2',
                style: AppText.label(11, color: AppColors.accent)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width > 600
                  ? 600.0
                  : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.lg),
            children: [
              // ── JOB INFO ─────────────────────────
              SectionCard(
                  child: Column(children: [
                CardHeader(
                    icon: Icons.work_outline_rounded,
                    iconBg: AppColors.accent.withOpacity(0.1),
                    iconColor: AppColors.accent,
                    title: 'Job Info',
                    trailing: _RequiredBadge()),
                const SizedBox(height: 12),
                _InputField(
                    label: 'Job Title',
                    initial: vm.title,
                    onChanged: (v) => vm.title = v),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _InputField(
                          label: 'Department',
                          initial: vm.department,
                          onChanged: (v) => vm.department = v)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _InputField(
                          label: 'Location',
                          initial: vm.location,
                          onChanged: (v) => vm.location = v)),
                ]),
                const SizedBox(height: AppSpace.sm),
                Text('Job Type',
                    style: AppText.caption(11).copyWith(letterSpacing: 0.04)),
                const SizedBox(height: 6),
                Row(
                    children: _jobTypes
                        .map((t) => Expanded(
                            child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: GestureDetector(
                                  onTap: () => setState(() => vm.jobType = t),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                        color: vm.jobType == t
                                            ? AppColors.ink
                                            : AppColors.surface,
                                        borderRadius:
                                            BorderRadius.circular(AppRadius.sm),
                                        border: Border.all(
                                            color: AppColors.border2)),
                                    child: Center(
                                        child: Text(
                                      t,
                                      style: AppText.label(10,
                                          color: vm.jobType == t
                                              ? Colors.white
                                              : AppColors.ink2),
                                    )),
                                  ),
                                ))))
                        .toList()),
              ])),

              // ── REQUIRED SKILLS ─────────────────
              SectionCard(
                  child: Column(children: [
                CardHeader(
                    icon: Icons.check_circle_outline_rounded,
                    iconBg: AppColors.green.withOpacity(0.1),
                    iconColor: AppColors.green,
                    title: 'Required Skills',
                    trailing: _RequiredBadge()),
                const SizedBox(height: 10),
                Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: vm.requiredSkills
                        .map((s) => SkillTag(
                              s,
                              required: true,
                              onRemove: () => vm.removeRequiredSkill(s),
                            ))
                        .toList()),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _InputField(
                          label: 'Add required skill…',
                          controller: _skillCtrl,
                          compact: true)),
                  const SizedBox(width: 6),
                  GestureDetector(
                      onTap: () {
                        vm.addRequiredSkill(_skillCtrl.text.trim());
                        _skillCtrl.clear();
                      },
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('Add',
                              style: AppText.title(12, color: Colors.white)))),
                ]),
              ])),

              // ── OPTIONAL SKILLS ─────────────────
              SectionCard(
                  child: Column(children: [
                CardHeader(
                    icon: Icons.info_outline_rounded,
                    iconBg: AppColors.amber.withOpacity(0.12),
                    iconColor: AppColors.amber,
                    title: 'Nice-to-Have Skills',
                    trailing: _OptionalBadge()),
                const SizedBox(height: 10),
                Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: vm.optionalSkills
                        .map((s) => SkillTag(
                              s,
                              required: false,
                              onRemove: () => vm.removeOptionalSkill(s),
                            ))
                        .toList()),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _InputField(
                          label: 'Add optional skill…',
                          controller: _optSkillCtrl,
                          compact: true)),
                  const SizedBox(width: 6),
                  GestureDetector(
                      onTap: () {
                        vm.addOptionalSkill(_optSkillCtrl.text.trim());
                        _optSkillCtrl.clear();
                      },
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border2)),
                          child: Text('Add', style: AppText.title(12)))),
                ]),
              ])),

              // ── EXPERIENCE ─────────────────────
              SectionCard(
                  child: Column(children: [
                CardHeader(
                    icon: Icons.access_time_rounded,
                    iconBg: AppColors.red.withOpacity(0.1),
                    iconColor: AppColors.red,
                    title: 'Experience Required',
                    trailing: _RequiredBadge()),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _StepBtn(
                      label: '−',
                      filled: false,
                      onTap: () => vm.decrementExp()),
                  const SizedBox(width: 24),
                  Column(children: [
                    Text('${vm.minExperience}+', style: AppText.headline(28)),
                    Text('years minimum', style: AppText.caption(12)),
                  ]),
                  const SizedBox(width: 24),
                  _StepBtn(
                      label: '+', filled: true, onTap: () => vm.incrementExp()),
                ]),
              ])),

              // ── EDUCATION ─────────────────────
              SectionCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    CardHeader(
                        icon: Icons.school_rounded,
                        iconBg: AppColors.accent.withOpacity(0.08),
                        iconColor: AppColors.accent,
                        title: 'Education Level',
                        trailing: _RequiredBadge()),
                    const SizedBox(height: 10),
                    Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _eduLevels
                            .map((e) => GestureDetector(
                                onTap: () => setState(() => vm.education = e),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: vm.education == e
                                          ? AppColors.ink
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(20),
                                      border:
                                          Border.all(color: AppColors.border2)),
                                  child: Text(e,
                                      style: AppText.label(12,
                                          color: vm.education == e
                                              ? Colors.white
                                              : AppColors.ink2)),
                                )))
                            .toList()),
                  ])),

              // ── AI MATCH WEIGHTS ───────────────
              SectionCard(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    CardHeader(
                        icon: Icons.bar_chart_rounded,
                        iconBg: AppColors.accent.withOpacity(0.1),
                        iconColor: AppColors.accent,
                        title: 'AI Match Weights',
                        trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text('AI Settings',
                                style: AppText.label(10,
                                    color: AppColors.accent)))),
                    const SizedBox(height: 6),
                    Text(
                        'Set how much the AI should prioritise each factor '
                        'when scoring candidates.',
                        style: AppText.caption(12)),
                    const SizedBox(height: 12),
                    _WeightSlider(
                        label: 'Skills match',
                        value: vm.skillWeight,
                        color: AppColors.accent,
                        onChanged: (v) => vm.setSkillWeight(v)),
                    _WeightSlider(
                        label: 'Experience',
                        value: vm.experienceWeight,
                        color: AppColors.green,
                        onChanged: null), // auto-calculated
                    _WeightSlider(
                        label: 'Education',
                        value: vm.educationWeight,
                        color: AppColors.amber,
                        onChanged: null), // auto-calculated
                  ])),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),

      // ── Sticky Find Matches Button ─────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: vm.isMatching ? null : () => _findMatches(context, vm),
            icon: vm.isMatching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.search_rounded, size: 20),
            label: Text(
                vm.isMatching ? 'Finding Matches…' : 'Find Matching Candidates',
                style: AppText.title(15, color: Colors.white)),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
          ),
        ),
      ),
    );
  }

  Future<void> _findMatches(BuildContext context, JobViewModel vm) async {
    await vm.findMatches();
    if (vm.matchResult != null && mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                  value: vm, child: const MatchResultsScreen())));
    }
  }
}

// ── Small widgets ────────────────────────────
class _RequiredBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: AppColors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5)),
      child: Text('Required', style: AppText.label(10, color: AppColors.red)));
}

class _OptionalBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.border2)),
      child: Text('Optional', style: AppText.label(10, color: AppColors.ink3)));
}

class _InputField extends StatelessWidget {
  final String label;
  final String? initial;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool compact;
  const _InputField(
      {required this.label,
      this.initial,
      this.onChanged,
      this.controller,
      this.compact = false});
  @override
  Widget build(BuildContext context) => Container(
      padding:
          EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 10 : 12),
      decoration:
          AppDecor.field(filled: initial != null && initial!.isNotEmpty),
      child: TextFormField(
          initialValue: controller == null ? initial : null,
          controller: controller,
          onChanged: onChanged,
          style: AppText.body(13),
          decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: label,
              hintStyle: AppText.caption(13))));
}

class _StepBtn extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _StepBtn(
      {required this.label, required this.filled, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: filled ? AppColors.accent : AppColors.surface,
              borderRadius: BorderRadius.circular(9),
              border: filled ? null : Border.all(color: AppColors.border2)),
          child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 20,
                      color: filled ? Colors.white : AppColors.ink2,
                      fontWeight: FontWeight.w300)))));
}

class _WeightSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double>? onChanged;
  const _WeightSlider(
      {required this.label,
      required this.value,
      required this.color,
      required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final isLocked = onChanged == null;
    return Opacity(
      opacity: isLocked ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Text(label, style: AppText.body(12)),
              if (isLocked) ...[
                const SizedBox(width: 4),
                Icon(Icons.lock_outline_rounded,
                    size: 12, color: AppColors.ink3),
              ],
            ]),
            Text('${(value * 100).round()}%',
                style: AppText.label(12, color: color)),
          ]),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: AppColors.surface,
              thumbColor: color,
              overlayColor: color.withOpacity(0.1),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: value,
              min: 0.1,
              max: 0.8,
              onChanged: onChanged,
            ),
          ),
        ]),
      ),
    );
  }
}
