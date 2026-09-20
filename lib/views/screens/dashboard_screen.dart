// lib/views/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../../models/models.dart';
import '../widgets/shared_widgets.dart';
import 'upload_screen.dart';
import 'candidate_detail_screen.dart';
import 'job_requirements_screen.dart';
import 'shortlist_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  final _titles = const [
    'Dashboard',
    'Resume Upload',
    'Job Requirements',
    'Shortlist'
  ];

  void _goTo(int index) {
    setState(() => _navIndex = index);
    if (index == 0) {
      context.read<DashboardViewModel>().loadDashboard();
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
      const JobRequirementsScreen(),
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
            Text('Welcome back,', style: AppText.caption(13, color: Colors.white60)),
            const SizedBox(height: 4),
            Text(name, style: AppText.headline(24, color: Colors.white)),
            const SizedBox(height: 22),
            if (vm.isLoading) 
              const Center(child: CircularProgressIndicator(color: Colors.white))
            else 
              Row(children: [
                _StatCard(number: vm.totalCVs.toString(), label: 'Total CVs'),
                const SizedBox(width: 8),
                _StatCard(number: vm.shortlisted.toString(), label: 'Shortlisted'),
                const SizedBox(width: 8),
                _StatCard(number: vm.openJobs.toString(), label: 'Open Jobs'),
              ]),
          ]),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String number, label;
  const _StatCard({required this.number, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Text(number, style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: AppText.caption(10, color: Colors.white38)),
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
      const SectionTitle('Quick Actions'),
      const SizedBox(height: 12),
      GridView.count(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, shrinkWrap: true, childAspectRatio: 2.2,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _ActionCard(icon: Icons.cloud_upload, title: 'Upload', color: AppColors.accent, onTap: () => onNavigate(1)),
          _ActionCard(icon: Icons.work, title: 'Jobs', color: AppColors.purple, onTap: () => onNavigate(2)),
          _ActionCard(icon: Icons.auto_awesome, title: 'Match', color: AppColors.green, onTap: () => onNavigate(2)),
          _ActionCard(icon: Icons.people, title: 'Shortlist', color: AppColors.amber, onTap: () => onNavigate(3)),
        ],
      ),
      const SizedBox(height: 24),
      const SectionTitle('Recent Candidates'),
      const SizedBox(height: 12),
      if (vm.topCandidates.isEmpty)
        const StandardEmptyView(title: 'No candidates yet', subtitle: 'Upload a resume to see candidates here.')
      else
        ...vm.topCandidates.map((c) => CandidateListCard(candidate: c, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CandidateDetailScreen(candidate: c))))),
    ]);
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String title; final Color color; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecor.card(radius: 14),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 10),
        Text(title, style: AppText.title(14)),
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
    destinations: const [
      NavigationDestination(icon: Icon(Icons.grid_view), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.upload_file), label: 'Upload'),
      NavigationDestination(icon: Icon(Icons.work), label: 'Jobs'),
      NavigationDestination(icon: Icon(Icons.stars), label: 'Shortlist'),
    ],
  );
}

class _DesktopRail extends StatelessWidget {
  final int selectedIndex; final ValueChanged<int> onSelected; final VoidCallback onLogout;
  const _DesktopRail({required this.selectedIndex, required this.onSelected, required this.onLogout});
  @override
  Widget build(BuildContext context) => NavigationRail(
    extended: true, selectedIndex: selectedIndex, onDestinationSelected: onSelected,
    leading: const Padding(padding: EdgeInsets.all(16), child: RecruitIQLogo(size: 40)),
    destinations: const [
      NavigationRailDestination(icon: Icon(Icons.grid_view), label: Text('Dashboard')),
      NavigationRailDestination(icon: Icon(Icons.upload_file), label: Text('Upload')),
      NavigationRailDestination(icon: Icon(Icons.work), label: Text('Jobs')),
      NavigationRailDestination(icon: Icon(Icons.stars), label: Text('Shortlist')),
    ],
    trailing: IconButton(onPressed: onLogout, icon: const Icon(Icons.logout)),
  );
}
