// lib/views/screens/jobs_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../../utils/toast_helper.dart';
import '../../models/models.dart';
import '../widgets/shared_widgets.dart';
import 'job_requirements_screen.dart';
import 'match_results_screen.dart';

class JobsListScreen extends StatefulWidget {
  const JobsListScreen({super.key});

  @override
  State<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends State<JobsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobViewModel>().loadJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JobViewModel>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppTopBar(
        title: 'Recruitment Jobs',
        showBack: false,
        actions: [
          IconButton(
            onPressed: () => _createNewJob(context, vm),
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.loadJobs,
        color: AppColors.accent,
        child: vm.isLoading && vm.jobs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : vm.error != null
                ? StandardErrorView(message: vm.error!, onRetry: vm.loadJobs)
                : vm.jobs.isEmpty
                    ? StandardEmptyView(
                        title: 'No Job Postings',
                        subtitle: 'Create a recruitment criteria to start matching candidates.',
                        icon: Icons.assignment_outlined,
                        action: ElevatedButton.icon(
                          onPressed: () => _createNewJob(context, vm),
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Job'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.jobs.length,
                        itemBuilder: (context, index) {
                          final job = vm.jobs[index];
                          return _JobCard(job: job, vm: vm);
                        },
                      ),
      ),
    );
  }

  void _createNewJob(BuildContext context, JobViewModel vm) {
    vm.resetForm();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JobRequirementsScreen()),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobRequirement job;
  final JobViewModel vm;
  const _JobCard({required this.job, required this.vm});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work_outline_rounded, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: AppText.title(15), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${job.department} · ${job.location}', style: AppText.caption(11)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (val) => _handleMenu(context, val),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.red))])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: job.requiredSkills.take(3).map((s) => SkillTag(s, required: true)).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editJob(context),
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: const Text('Criteria'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _matchCandidates(context),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('AI Match'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editJob(BuildContext context) {
    vm.setFromJob(job);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JobRequirementsScreen()),
    );
  }

  Future<void> _matchCandidates(BuildContext context) async {
    final success = await vm.findMatches(existingJob: job);
    if (context.mounted) {
      if (success) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MatchResultsScreen()),
        );
      } else if (vm.error != null) {
        ToastHelper.error(context, vm.error!);
      }
    }
  }

  void _handleMenu(BuildContext context, String action) {
    if (action == 'edit') {
      _editJob(context);
    } else if (action == 'delete') {
      _confirmDelete(context);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Job'),
        content: Text('Are you sure you want to remove the "${job.title}" posting?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              vm.deleteJob(job.id!);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
