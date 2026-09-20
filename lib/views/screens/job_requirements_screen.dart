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
  final _minSalaryCtrl = TextEditingController();
  final _maxSalaryCtrl = TextEditingController();

  final List<String> _jobTypes = ['Full Time', 'Part Time', 'Remote', 'Contract'];
  final List<String> _eduLevels = ['Matric', 'Intermediate', 'BSc / BE', 'MSc / MS', 'PhD'];

  @override
  void dispose() {
    _skillCtrl.dispose();
    _optSkillCtrl.dispose();
    _minSalaryCtrl.dispose();
    _maxSalaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _findMatches(BuildContext context, JobViewModel vm) async {
    final success = await vm.findMatches();
    if (!mounted) return;
    
    if (success) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => MatchResultsScreen()));
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
                // ── Position Details ───────────────────
                SectionCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const CardHeader(icon: Icons.work_outline_rounded, iconBg: Colors.white, iconColor: AppColors.accent, title: 'Position Details'),
                    const SizedBox(height: 16),
                    _InputField(label: 'Job Title', initial: vm.title, onChanged: (v) => vm.title = v),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _InputField(label: 'Department', initial: vm.department, onChanged: (v) => vm.department = v)),
                      const SizedBox(width: 12),
                      Expanded(child: _InputField(label: 'Location', initial: vm.location, onChanged: (v) => vm.location = v)),
                    ]),
                    const SizedBox(height: 20),
                    Text('Employment Type', style: AppText.label(12)),
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, children: _jobTypes.map((t) => ChoiceChip(
                      label: Text(t, style: const TextStyle(fontSize: 12)), 
                      selected: vm.jobType == t,
                      onSelected: (_) => setState(() => vm.jobType = t),
                    )).toList()),
                  ]),
                ),

                // ── Education & Salary ────────────────
                SectionCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const CardHeader(icon: Icons.school_outlined, iconBg: Colors.white, iconColor: AppColors.teal, title: 'Qualifications'),
                    const SizedBox(height: 16),
                    Text('Min. Education Level', style: AppText.label(12)),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: _eduLevels.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(e), selected: vm.educationLevel == e,
                          onSelected: (_) => setState(() => vm.educationLevel = e),
                        ),
                      )).toList()),
                    ),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Experience (Years)', style: AppText.label(12)),
                        const SizedBox(height: 8),
                        Row(children: [
                          _StepperBtn(icon: Icons.remove, onTap: vm.decrementExp),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(vm.minExperience.toString(), style: AppText.title(16))),
                          _StepperBtn(icon: Icons.add, onTap: vm.incrementExp),
                        ]),
                      ])),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Salary Range (PKR)', style: AppText.label(12)),
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: _InputField(label: 'Min', initial: vm.salaryMin.toString(), onChanged: (v) => vm.salaryMin = int.tryParse(v) ?? 0, compact: true)),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('—')),
                          Expanded(child: _InputField(label: 'Max', initial: vm.salaryMax.toString(), onChanged: (v) => vm.salaryMax = int.tryParse(v) ?? 0, compact: true)),
                        ]),
                      ])),
                    ]),
                  ]),
                ),

                // ── Required Skills ───────────────────
                SectionCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const CardHeader(icon: Icons.bolt_rounded, iconBg: Colors.white, iconColor: AppColors.amber, title: 'Required Skills'),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: vm.requiredSkills.map((s) => SkillTag(s, onRemove: () => vm.removeRequiredSkill(s))).toList()),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _InputField(label: 'Add a mandatory skill...', controller: _skillCtrl, compact: true)),
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

                // ── Optional Skills ───────────────────
                SectionCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const CardHeader(icon: Icons.auto_awesome_outlined, iconBg: Colors.white, iconColor: AppColors.purple, title: 'Optional / Bonus Skills'),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: vm.optionalSkills.map((s) => SkillTag(s, required: false, onRemove: () => vm.removeOptionalSkill(s))).toList()),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _InputField(label: 'Add a nice-to-have skill...', controller: _optSkillCtrl, compact: true)),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: AppColors.purple),
                        onPressed: () {
                          vm.addOptionalSkill(_optSkillCtrl.text.trim());
                          _optSkillCtrl.clear();
                        },
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ]),
                  ]),
                ),

                // ── Match Weights ─────────────────────
                SectionCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const CardHeader(icon: Icons.tune_rounded, iconBg: Colors.white, iconColor: AppColors.green, title: 'AI Matching Priorities'),
                    const SizedBox(height: 6),
                    Text('Adjust these to tell the AI what matters most.', style: AppText.caption(11)),
                    const SizedBox(height: 20),
                    _WeightSlider(label: 'Technical Skills', value: vm.skillWeight, color: AppColors.accent, onChanged: (v) => vm.updateWeights(skill: v)),
                    _WeightSlider(label: 'Years of Experience', value: vm.experienceWeight, color: AppColors.green, onChanged: (v) => vm.updateWeights(exp: v)),
                    _WeightSlider(label: 'Education Level', value: vm.educationWeight, color: AppColors.orange, onChanged: (v) => vm.updateWeights(edu: v)),
                  ]),
                ),

                const SizedBox(height: 100),
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

class _StepperBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _StepperBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton.outlined(
    onPressed: onTap, icon: Icon(icon, size: 18),
    style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
  );
}

class _WeightSlider extends StatelessWidget {
  final String label; final double value; final Color color; final ValueChanged<double> onChanged;
  const _WeightSlider({required this.label, required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppText.label(12)),
        Text('${(value * 100).round()}%', style: AppText.title(13, color: color)),
      ]),
      Slider(
        value: value, min: 0.05, max: 0.8, activeColor: color, 
        onChanged: (v) => onChanged(double.parse(v.toStringAsFixed(2))),
      ),
    ]);
  }
}
