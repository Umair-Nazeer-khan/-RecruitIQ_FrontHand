import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/models.dart';
import '../../utils/app_constants.dart';

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
        border: Border.all(color: scoreColor(score).withOpacity(.12)),
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
          colors: [avatarColor(name), avatarColor(name).withOpacity(.72)],
        ),
        borderRadius: BorderRadius.circular(size * .28),
        boxShadow: [
          BoxShadow(
            color: avatarColor(name).withOpacity(.16),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
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
    final bg = required ? AppColors.accent.withOpacity(.09) : AppColors.surface;
    final fg = required ? AppColors.accentDark : AppColors.ink2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color:
              required ? AppColors.accent.withOpacity(.16) : AppColors.border2,
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
                  size: 14, color: fg.withOpacity(.55)),
            ),
          ],
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
        side: BorderSide(color: AppColors.border2),
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
                    Text(candidate.name,
                        style: AppText.title(13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(
                      '${candidate.skills.take(2).join(', ')}${candidate.skills.isNotEmpty ? ' · ' : ''}${candidate.experienceYears.toStringAsFixed(0)} yrs experience',
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
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.ink3, size: 20),
            ],
          ),
        ),
      ),
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

class AiBadge extends StatelessWidget {
  final String text;
  const AiBadge({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(.09),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.accent.withOpacity(.15)),
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

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const StatusChip({required this.label, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppText.caption(10, color: color)
            .copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  const ResponsiveCenter({
    required this.child,
    this.maxWidth = 1180,
    this.padding = const EdgeInsets.symmetric(horizontal: 18),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: AppDecor.card(radius: 18),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.accent, size: 28),
          ),
          const SizedBox(height: 15),
          Text(title, style: AppText.title(15)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppText.caption(11),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.auto_awesome_rounded, size: 17),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

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
                tooltip: 'Back',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.ink,
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 19),
              ),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const RecruitIQLogo(size: 28, shadow: false),
          const SizedBox(width: 9),
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
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
                  color: AppColors.orange.withOpacity(.20),
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
