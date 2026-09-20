import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';
import '../../utils/app_constants.dart';

// ── PILLS & BADGES ──────────────────────────────────────────

class ScorePill extends StatelessWidget {
  final double score;
  const ScorePill(this.score, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scoreBgColor(score),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: scoreColor(score).withValues(alpha: 0.12)),
      ),
      child: Text(
        '${score.toInt()}%',
        style: GoogleFonts.syne(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: scoreColor(score),
        ),
      ),
    );
  }
}

class AiBadge extends StatelessWidget {
  final String text;
  const AiBadge({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppText.caption(8, color: AppColors.accent).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: .06,
            ),
          ),
        ],
      ),
    );
  }
}

// ── REUSABLE UI BLOCKS ──────────────────────────────────────

class AvatarCircle extends StatelessWidget {
  final String name;
  final double size;
  const AvatarCircle(this.name, {this.size = 38, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [avatarColor(name), avatarColor(name).withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(size * .28),
      ),
      child: Center(
        child: Text(
          initials(name),
          style: GoogleFonts.syne(
            fontSize: size * .32,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.label(10, color: AppColors.ink3).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: .10,
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;

  const SectionCard({
    required this.child,
    this.padding,
    this.margin,
    this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: AppDecor.card(radius: 18).copyWith(
        color: color ?? AppColors.cardBg,
      ),
      child: child,
    );
  }
}

class SkillMatchBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String display;

  const SkillMatchBar({
    required this.label,
    required this.value,
    required this.color,
    required this.display,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 86, child: Text(label, style: AppText.caption(11))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value.clamp(0, 1),
                minHeight: 7,
                backgroundColor: AppColors.surface,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 42,
            child: Text(
              display,
              style: AppText.label(10, color: color)
                  .copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class CandidateListCard extends StatelessWidget {
  final Candidate candidate;
  final VoidCallback? onTap;

  const CandidateListCard({required this.candidate, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final score = candidate.matchScore;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AvatarCircle(candidate.name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.name,
                      style: AppText.title(13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${candidate.skills.take(3).join(', ')}${candidate.skills.length > 3 ? '...' : ''} · ${candidate.experienceYears.toStringAsFixed(0)}y exp',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption(10),
                    ),
                  ],
                ),
              ),
              if (score != null) ...[
                const SizedBox(width: 8),
                ScorePill(score),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.ink3, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── PROFESSIONAL STATE VIEWS ──────────────────

class StandardErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const StandardErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  color: AppColors.red, size: 32),
            ),
            const SizedBox(height: 20),
            Text('Something went wrong', style: AppText.title(16)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.caption(13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StandardEmptyView extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;

  const StandardEmptyView({
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_rounded,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.ink3.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Text(title, style: AppText.title(15)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppText.caption(12),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ── LOADING OVERLAY ─────────────────────────────────────────

class AppLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;

  const AppLoadingOverlay({
    required this.child,
    required this.isLoading,
    this.message,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(strokeWidth: 3),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: AppText.label(13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── NAVIGATION & LAYOUT ─────────────────────────────────────

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const AppTopBar({
    required this.title,
    this.actions,
    this.showBack = true,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(62);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.cardBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? Padding(
              padding: const EdgeInsets.all(9),
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.ink,
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 19),
              ),
            )
          : null,
      title: Text(title, style: AppText.title(17)),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }
}

class SkillTag extends StatelessWidget {
  final String label;
  final bool required;
  final VoidCallback? onRemove;

  const SkillTag(
    this.label, {
    this.required = true,
    this.onRemove,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bg = required ? AppColors.accent.withValues(alpha: 0.09) : AppColors.surface;
    final fg = required ? AppColors.accentDark : AppColors.ink2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color:
              required ? AppColors.accent.withValues(alpha: 0.16) : AppColors.border2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (required)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: Icon(Icons.check_rounded, size: 13, color: fg),
            ),
          Text(label, style: AppText.label(11, color: fg)),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(20),
              child: Icon(Icons.close_rounded,
                  size: 14, color: fg.withValues(alpha: 0.55)),
            ),
          ],
        ],
      ),
    );
  }
}

class CardHeader extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Widget? trailing;

  const CardHeader({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: AppText.title(13),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class RecruitIQLogo extends StatelessWidget {
  final double size;
  final bool shadow;

  const RecruitIQLogo({this.size = 52, this.shadow = true, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.logoAqua,
        borderRadius: BorderRadius.circular(size * .24),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.20),
                  blurRadius: size * .28,
                  offset: Offset(0, size * .10),
                )
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/icon/image.png', fit: BoxFit.cover),
    );
  }
}
