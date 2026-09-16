// lib/views/screens/dashboard_screen.dart
//
// RecruitIQ — responsive FYP dashboard
// Designed for mobile, tablet and desktop/web evaluation.

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
                  title: _titles[_navIndex],
                  onSelected: _goTo,
                  onLogout: () => _showLogoutDialog(context),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _navIndex,
                    children: screens,
                  ),
                ),
              ],
            )
          : IndexedStack(
              index: _navIndex,
              children: screens,
            ),
      bottomNavigationBar: isWide
          ? null
          : _MobileNavigation(
              selectedIndex: _navIndex,
              onSelected: _goTo,
            ),
      floatingActionButton: !isWide && _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _goTo(1),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Screen Resume'),
            )
          : null,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('Sign Out', style: AppText.title(18)),
        content: Text(
          'Are you sure you want to sign out of RecruitIQ?',
          style: AppText.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppText.label(13)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthViewModel>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DESKTOP NAVIGATION RAIL
// ─────────────────────────────────────────────

class _DesktopRail extends StatelessWidget {
  final int selectedIndex;
  final String title;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  const _DesktopRail({
    required this.selectedIndex,
    required this.title,
    required this.onSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
              child: Row(
                children: [
                  const RecruitIQLogo(size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RecruitIQ',
                          style: AppText.title(17),
                        ),
                        Text(
                          'AI RECRUITMENT',
                          style: AppText.caption(9).copyWith(
                            letterSpacing: .12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AiBadge(text: 'AI SCREENING ACTIVE'),
            ),
            const SizedBox(height: 26),
            Expanded(
              child: NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onSelected,
                extended: true,
                backgroundColor: Colors.transparent,
                indicatorColor: AppColors.accent.withOpacity(.10),
                selectedIconTheme: const IconThemeData(
                  color: AppColors.accent,
                ),
                unselectedIconTheme: IconThemeData(
                  color: AppColors.ink3,
                ),
                selectedLabelTextStyle: AppText.label(
                  13,
                  color: AppColors.accent,
                ).copyWith(fontWeight: FontWeight.w700),
                unselectedLabelTextStyle: AppText.label(
                  13,
                  color: AppColors.ink3,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.cloud_upload_outlined),
                    selectedIcon: Icon(Icons.cloud_upload_rounded),
                    label: Text('Resume Upload'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.work_outline_rounded),
                    selectedIcon: Icon(Icons.work_rounded),
                    label: Text('Job Requirements'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline_rounded),
                    selectedIcon: Icon(Icons.people_rounded),
                    label: Text('Shortlist'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: onLogout,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  side: BorderSide(color: AppColors.border2),
                  foregroundColor: AppColors.ink2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MOBILE NAVIGATION
// ─────────────────────────────────────────────

class _MobileNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _MobileNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      height: 72,
      backgroundColor: AppColors.cardBg,
      elevation: 8,
      indicatorColor: AppColors.accent.withOpacity(.12),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppText.caption(
          10,
          color: states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.ink3,
        ).copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.cloud_upload_outlined),
          selectedIcon: Icon(Icons.cloud_upload_rounded),
          label: 'Upload',
        ),
        NavigationDestination(
          icon: Icon(Icons.work_outline_rounded),
          selectedIcon: Icon(Icons.work_rounded),
          label: 'Jobs',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Shortlist',
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// HOME
// ─────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final void Function(int) onNavigate;

  const _HomeTab({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final vm = context.watch<DashboardViewModel>();
    final name = authVm.currentUser?.name ?? 'there';

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 1200
        ? 44.0
        : width >= 700
            ? 32.0
            : 18.0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => context.read<DashboardViewModel>().loadDashboard(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHero(
                greeting: greeting,
                name: name,
                vm: vm,
                horizontalPadding: horizontal,
                onLogout: () => _showLogoutDialog(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      24,
                      horizontal,
                      40,
                    ),
                    child: _DashboardBody(
                      vm: vm,
                      onNavigate: onNavigate,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text('Sign Out', style: AppText.title(18)),
        content: Text(
          'Are you sure you want to sign out of RecruitIQ?',
          style: AppText.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthViewModel>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (_) => false,
                );
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final String greeting;
  final String name;
  final DashboardViewModel vm;
  final double horizontalPadding;
  final VoidCallback onLogout;

  const _DashboardHero({
    required this.greeting,
    required this.name,
    required this.vm,
    required this.horizontalPadding,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.ink,
            AppColors.accentDark,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                28,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greeting,
                              style: AppText.caption(
                                13,
                                color: Colors.white.withOpacity(.60),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.headline(
                                24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'AI-assisted hiring, from resume to shortlist.',
                              style: AppText.body(
                                12,
                                color: Colors.white.withOpacity(.58),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sign out',
                        onPressed: onLogout,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(.10),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (vm.isLoading)
                    const SizedBox(
                      height: 92,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoRows = constraints.maxWidth < 520;

                        final cards = [
                          _StatBox(
                            number: vm.totalCVs.toString(),
                            label: 'Total CVs',
                            icon: Icons.description_outlined,
                            trend: 'Parsed',
                          ),
                          _StatBox(
                            number: vm.shortlisted.toString(),
                            label: 'Shortlisted',
                            icon: Icons.stars_rounded,
                            trend: 'Selected',
                          ),
                          _StatBox(
                            number: vm.openJobs.toString(),
                            label: 'Open Jobs',
                            icon: Icons.work_outline_rounded,
                            trend: 'Active',
                          ),
                        ];

                        if (twoRows) {
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: cards
                                .map(
                                  (card) => SizedBox(
                                    width: (constraints.maxWidth - 8) / 2,
                                    child: card,
                                  ),
                                )
                                .toList(),
                          );
                        }

                        return Row(
                          children: [
                            for (int i = 0; i < cards.length; i++) ...[
                              Expanded(child: cards[i]),
                              if (i != cards.length - 1)
                                const SizedBox(width: 10),
                            ],
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardViewModel vm;
  final void Function(int) onNavigate;

  const _DashboardBody({
    required this.vm,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(50),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Quick Actions'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 4
                : constraints.maxWidth >= 600
                    ? 2
                    : 1;

            final gap = 12.0;
            final itemWidth =
                (constraints.maxWidth - gap * (columns - 1)) / columns;

            final actions = [
              _ActionTile(
                icon: Icons.cloud_upload_rounded,
                title: 'Upload Resume',
                subtitle: 'PDF, DOCX or TXT',
                color: AppColors.accent,
                onTap: () => onNavigate(1),
              ),
              _ActionTile(
                icon: Icons.work_history_rounded,
                title: 'Create Job',
                subtitle: 'Define requirements',
                color: AppColors.purple,
                onTap: () => onNavigate(2),
              ),
              _ActionTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Run Matching',
                subtitle: 'Compare candidates',
                color: AppColors.green,
                onTap: () => onNavigate(2),
              ),
              _ActionTile(
                icon: Icons.people_alt_rounded,
                title: 'View Shortlist',
                subtitle: 'Review top talent',
                color: AppColors.amber,
                onTap: () => onNavigate(3),
              ),
            ];

            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: actions
                  .map(
                    (action) => SizedBox(
                      width: itemWidth,
                      child: action,
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: Text(
                'Top Candidates',
                style: AppText.headline(18),
              ),
            ),
            TextButton.icon(
              onPressed: () => onNavigate(3),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('View shortlist'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (vm.topCandidates.isEmpty)
          const _EmptyState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final candidates = vm.topCandidates.take(6).toList();

              if (constraints.maxWidth >= 850) {
                return GridView.builder(
                  itemCount: candidates.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3.35,
                  ),
                  itemBuilder: (_, index) =>
                      _CandidateTile(candidate: candidates[index]),
                );
              }

              return Column(
                children: candidates
                    .map(
                      (candidate) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CandidateTile(candidate: candidate),
                      ),
                    )
                    .toList(),
              );
            },
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.cardBg,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.title(13)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: AppText.caption(10)),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: AppColors.ink3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final Candidate candidate;

  const _CandidateTile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final score = candidate.matchScore ?? 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CandidateDetailScreen(candidate: candidate),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AvatarCircle(candidate.name, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      candidate.education.isEmpty
                          ? 'Candidate profile'
                          : candidate.education,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption(10),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.work_history_outlined,
                          size: 13,
                          color: AppColors.ink3,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${candidate.experienceYears} yrs experience',
                          style: AppText.caption(10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ScorePill(score),
                  const SizedBox(height: 5),
                  Text(
                    score >= 80
                        ? 'Strong match'
                        : score >= 60
                            ? 'Good match'
                            : 'Review',
                    style: AppText.caption(
                      9,
                      color: scoreColor(score),
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final String trend;

  const _StatBox({
    required this.number,
    required this.label,
    required this.icon,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.075),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white.withOpacity(.72),
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  number,
                  style: GoogleFonts.syne(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption(
                    9,
                    color: Colors.white.withOpacity(.48),
                  ),
                ),
              ],
            ),
          ),
          Text(
            trend,
            style: AppText.caption(
              9,
              color: Colors.white.withOpacity(.40),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text('No candidates yet', style: AppText.title(15)),
          const SizedBox(height: 5),
          Text(
            'Upload a resume and RecruitIQ will extract skills,\n'
            'experience and education automatically.',
            textAlign: TextAlign.center,
            style: AppText.caption(11),
          ),
        ],
      ),
    );
  }
}
