// lib/views/screens/job_requirements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../../utils/toast_helper.dart';
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

  final List<String> _jobTypes = ['Full Time', 'Part Time', 'Remote', 'Contract'];
  final List<String> _eduLevels = ['Matric', 'Intermediate', 'BSc / BE', 'MSc / MS', 'PhD'];

  @override
  void dispose() {
    _skillCtrl.dispose();
    _optSkillCtrl.dispose();
    super.dispose();
  }

  Future<void> _findMatches(BuildContext context, JobViewModel vm) async {
    final success = await vm.findMatches();
    if (!mounted) return;
    
    if (success) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(value: vm, child: const MatchResultsScreen())));
    } else if (vm.error != null) {
      ToastHelper.error(context, vm.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JobViewModel>();

    return AppLoadingOverlay(
      isLoading: vm.isMatching,
      message: 'AI is analyzing candidates...',
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const AppTopBar(title: 'Recruitment Criteria', showBack: false),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.lg),
              children: [
                // ── Error Banner ─────────────────────
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.red.withOpacity(.08), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.red, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(vm.error!, style: AppText.body(13, color: AppColors.red))),
                      ]),
                    ),
                  ),

                // ── JOB INFO ─────────────────────────
                SectionCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const CardHeader(icon: Icons.work_outline_rounded, iconBg: Colors.white, iconColor: AppColors.accent, title: 'Position Details'),
                    const SizedBox(height: 16),
                    _InputField(label: 'Job Title (e.g. Flutter Developer)', initial: vm.title, onChanged: (v) => vm.title = v),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _InputField(label: 'Department', initial: vm.department, onChanged: (v) => vm.department = v)),
                      const SizedBox(width: 12),
                      Expanded(child: _InputField(label: 'Location', initial: vm.location, onChanged: (v) => vm.location = v)),
                    ]),
                    const SizedBox(height: 20),
                    Text('Employment Type', style: AppText.label(12)),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: _jobTypes.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t), selected: vm.jobType == t,
                          onSelected: (_) => setState(() => vm.jobType = t),
                        ),
                      )).toList()),
                    ),
                  ]),
                ),

                // ── REQUIRED SKILLS ─────────────────
                SectionCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const CardHeader(icon: Icons.bolt_rounded, iconBg: Colors.white, iconColor: AppColors.amber, title: 'Required Skills'),
                    const SizedBox(height: 12),
                    if (vm.requiredSkills.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Add skills the AI should look for.', style: AppText.caption(12)),
                      ),
                    Wrap(spacing: 8, runSpacing: 8, children: vm.requiredSkills.map((s) => SkillTag(s, onRemove: () => vm.removeRequiredSkill(s))).toList()),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _InputField(label: 'Enter a skill...', controller: _skillCtrl, compact: true)),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          vm.addRequiredSkill(_skillCtrl.text.trim());
                          _skillCtrl.clear();
                        },
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ]),
                  ]),
                ),

                // ── WEIGHTS ────────────────────────
                SectionCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const CardHeader(icon: Icons.tune_rounded, iconBg: Colors.white, iconColor: AppColors.green, title: 'AI Match Weights'),
                    const SizedBox(height: 6),
                    Text('Adjust how strictly the AI scores candidates.', style: AppText.caption(11)),
                    const SizedBox(height: 16),
                    _WeightSlider(label: 'Skills Priority', value: vm.skillWeight, color: AppColors.accent, onChanged: vm.setSkillWeight),
                    _WeightSlider(label: 'Experience Priority', value: vm.experienceWeight, color: AppColors.green, onChanged: null),
                  ]),
                ),

                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.cardBg, border: Border(top: BorderSide(color: AppColors.border))),
          child: SafeArea(
            child: FilledButton.icon(
              onPressed: () => _findMatches(context, vm),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Analyze & Rank Candidates'),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label; final String? initial; final ValueChanged<String>? onChanged;
  final TextEditingController? controller; final bool compact;
  const _InputField({required this.label, this.initial, this.onChanged, this.controller, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: controller == null ? initial : null,
      controller: controller,
      onChanged: onChanged,
      style: AppText.body(14),
      decoration: InputDecoration(
        hintText: label,
        isDense: compact,
        contentPadding: compact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12) : null,
      ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  final String label; final double value; final Color color; final ValueChanged<double>? onChanged;
  const _WeightSlider({required this.label, required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppText.label(12)),
        Text('${(value * 100).round()}%', style: AppText.title(13, color: color)),
      ]),
      Slider(value: value, min: 0.1, max: 0.8, activeColor: color, onChanged: onChanged),
    ]);
  }
}
