// lib/views/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/job_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../widgets/shared_widgets.dart';
import 'upload_screen.dart';
import 'candidate_detail_screen.dart';
import 'jobs_list_screen.dart';
import 'shortlist_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  void _goTo(int index) {
    setState(() => _navIndex = index);
    if (index == 0) {
      context.read<DashboardViewModel>().loadDashboard();
    } else if (index == 2) {
      // Use index 2 for Jobs
      context.read<JobViewModel>().loadJobs();
    } else if (index == 3) {
      context.read<CandidatesViewModel>().load();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardViewModel>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    final screens = [
      _HomeTab(onNavigate: _goTo),
      const UploadScreen(),
      const JobsListScreen(), // Integrated Job List
      const ShortlistScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: isWide
          ? Row(
              children: [
                _DesktopRail(
                  selectedIndex: _navIndex,
                  onSelected: _goTo,
                  onLogout: () => _showLogoutDialog(context),
                ),
                Expanded(child: IndexedStack(index: _navIndex, children: screens)),
              ],
            )
          : IndexedStack(index: _navIndex, children: screens),
      bottomNavigationBar: isWide ? null : _MobileNavigation(selectedIndex: _navIndex, onSelected: _goTo),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Sign Out', style: AppText.title(18)),
        content: const Text('Are you sure you want to sign out of RecruitIQ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthViewModel>().logout();
              if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final void Function(int) onNavigate;
  const _HomeTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final vm = context.watch<DashboardViewModel>();
    final name = authVm.currentUser?.name ?? 'Recruiter';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => context.read<DashboardViewModel>().loadDashboard(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _DashboardHero(name: name, vm: vm)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: vm.error != null 
                  ? StandardErrorView(message: vm.error!, onRetry: () => vm.loadDashboard())
                  : _DashboardBody(vm: vm, onNavigate: onNavigate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final String name;
  final DashboardViewModel vm;
  const _DashboardHero({required this.name, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.ink, AppColors.accentDark])),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xl, AppSpace.lg, AppSpace.xl),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,', style: AppText.caption(13, color: Colors.white60)),
                      const SizedBox(height: 4),
                      Text(name, style: AppText.headline(24, color: Colors.white)),
                    ],
                  ),
                ),
                const RecruitIQLogo(size: 42, shadow: false),
              ],
            ),
            const SizedBox(height: 24),
            if (vm.isLoading) 
              const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(color: Colors.white),
              ))
            else ...[
              Row(children: [
                _StatCard(number: vm.totalCVs.toString(), label: 'Total CVs', color: Colors.white),
                const SizedBox(width: 8),
                _StatCard(number: vm.openJobs.toString(), label: 'Open Jobs', color: AppColors.orange),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                _StatCard(number: vm.shortlisted.toString(), label: 'Shortlisted', color: Colors.blueAccent),
                const SizedBox(width: 8),
                _StatCard(number: vm.accepted.toString(), label: 'Hired', color: AppColors.green),
                const SizedBox(width: 8),
                _StatCard(number: vm.pending.toString(), label: 'New', color: Colors.white70),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String number, label;
  final Color color;
  const _StatCard({required this.number, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(number, style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppText.caption(9, color: Colors.white38).copyWith(fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}

class _DashboardBody extends StatelessWidget {
  final DashboardViewModel vm;
  final void Function(int) onNavigate;
  const _DashboardBody({required this.vm, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Recruitment Hub'),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, shrinkWrap: true, childAspectRatio: 2.2,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _ActionCard(icon: Icons.cloud_upload_outlined, title: 'Upload CV', color: AppColors.accent, onTap: () => onNavigate(1)),
          _ActionCard(icon: Icons.assignment_outlined, title: 'View Jobs', color: AppColors.green, onTap: () => onNavigate(2)),
          _ActionCard(icon: Icons.tune_rounded, title: 'Job Matching', color: AppColors.purple, onTap: () => onNavigate(2)),
          _ActionCard(icon: Icons.star_outline_rounded, title: 'Shortlist', color: AppColors.amber, onTap: () => onNavigate(3)),
        ],
      ),
      const SizedBox(height: 28),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SectionTitle('Recent Candidates'),
          TextButton(
            onPressed: () => onNavigate(3),
            child: Text('View Pipeline', style: AppText.label(12, color: AppColors.accent)),
          ),
        ],
      ),
      const SizedBox(height: 4),
      if (vm.topCandidates.isEmpty)
        const StandardEmptyView(title: 'No candidates yet', subtitle: 'Upload resumes to start screening process.')
      else
        ...vm.topCandidates.take(8).map((c) => CandidateListCard(
          candidate: c, 
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CandidateDetailScreen(candidate: c)))
        )),
      const SizedBox(height: 20),
    ]);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String title; final Color color; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecor.card(radius: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: AppText.title(13), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );
}

class _MobileNavigation extends StatelessWidget {
  final int selectedIndex; final ValueChanged<int> onSelected;
  const _MobileNavigation({required this.selectedIndex, required this.onSelected});
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex, onDestinationSelected: onSelected,
    height: 64,
    elevation: 0,
    backgroundColor: AppColors.cardBg,
    indicatorColor: AppColors.accent.withValues(alpha: 0.1),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.grid_view_rounded, size: 22), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.add_circle_outline_rounded, size: 22), label: 'Upload'),
      NavigationDestination(icon: Icon(Icons.work_outline_rounded, size: 22), label: 'Jobs'),
      NavigationDestination(icon: Icon(Icons.star_outline_rounded, size: 22), label: 'Talent'),
    ],
  );
}

class _DesktopRail extends StatelessWidget {
  final int selectedIndex; final ValueChanged<int> onSelected; final VoidCallback onLogout;
  const _DesktopRail({required this.selectedIndex, required this.onSelected, required this.onLogout});
  @override
  Widget build(BuildContext context) => NavigationRail(
    extended: true, selectedIndex: selectedIndex, onDestinationSelected: onSelected,
    backgroundColor: AppColors.ink,
    unselectedIconTheme: const IconThemeData(color: Colors.white54),
    selectedIconTheme: const IconThemeData(color: Colors.white),
    unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
    selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    leading: const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: RecruitIQLogo(size: 48)),
    destinations: const [
      NavigationRailDestination(icon: Icon(Icons.grid_view_rounded), label: Text('Dashboard')),
      NavigationRailDestination(icon: Icon(Icons.add_circle_outline_rounded), label: Text('Resume Upload')),
      NavigationRailDestination(icon: Icon(Icons.work_outline_rounded), label: Text('Job Match')),
      NavigationRailDestination(icon: Icon(Icons.star_outline_rounded), label: Text('Talent List')),
    ],
    trailing: Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: IconButton(onPressed: onLogout, icon: const Icon(Icons.logout_rounded, color: Colors.white70)),
        ),
      ),
    ),
  );
}
