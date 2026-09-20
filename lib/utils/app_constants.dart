// lib/utils/app_constants.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════
//  COLORS
// ═══════════════════════════════════════════════
class AppColors {
  // RecruitIQ logo palette: soft aqua background + deep teal + warm orange.
  static const Color logoAqua = Color(0xFFE4F5F5);
  static const Color logoAquaDeep = Color(0xFFCDE9E9);
  static const Color peach = Color(0xFFE5AD88);
  static const Color orange = Color(0xFFF58B2A);
  static const Color orangeDark = Color(0xFFD96D12);
  static const Color orangeSoft = Color(0xFFFFF0DF);
  static const Color teal = Color(0xFF176A68);
  static const Color tealLight = Color(0xFF278A86);
  static const Color tealDark = Color(0xFF0D4F4D);
  static const Color ink = Color(0xFF103F3D);
  static const Color ink2 = Color(0xFF496360);
  static const Color ink3 = Color(0xFF7E9491);
  static const Color surface = Color(0xFFF4FAF9);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color accent = teal;
  static const Color accentLight = tealLight;
  static const Color accentDark = tealDark;
  static const Color green = Color(0xFF168A67);
  static const Color red = Color(0xFFD94A42);
  static const Color amber = orange;
  static const Color purple = Color(0xFF3E817D);
  static const Color purpleBg = Color(0xFFE7F3F2);

  static const Color scoreHighFg = Color(0xFF14775B);
  static const Color scoreHighBg = Color(0xFFE5F6EF);
  static const Color scoreMidFg = Color(0xFFB76016);
  static const Color scoreMidBg = Color(0xFFFFF0E2);
  static const Color scoreLowFg = Color(0xFFC23830);
  static const Color scoreLowBg = Color(0xFFFCEAE8);

  static const Color border = Color(0x180D4F4D);
  static const Color border2 = Color(0x260D4F4D);
  static const Color divider = Color(0x100D4F4D);
}

// ═══════════════════════════════════════════════
//  SPACING SCALE — use these instead of raw numbers
//  so spacing stays consistent across every screen.
// ═══════════════════════════════════════════════
class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

// ═══════════════════════════════════════════════
//  TEXT STYLES
// ═══════════════════════════════════════════════
class AppText {
  static TextStyle headline(double size,
          {Color? color, double? letterSpacing}) =>
      GoogleFonts.syne(
          fontSize: size,
          fontWeight: FontWeight.w800,
          color: color ?? AppColors.ink,
          letterSpacing: letterSpacing);

  static TextStyle title(double size, {Color? color}) => GoogleFonts.syne(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.ink);

  static TextStyle label(double size, {Color? color}) => GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: FontWeight.w500,
      color: color ?? AppColors.ink2);

  static TextStyle body(double size, {Color? color}) => GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.ink2);

  static TextStyle caption(double size, {Color? color}) => GoogleFonts.dmSans(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: color ?? AppColors.ink3);
}

// ═══════════════════════════════════════════════
//  DECORATIONS
// ═══════════════════════════════════════════════
class AppDecor {
  static BoxDecoration card({double radius = 16}) => BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A0A1F1D), blurRadius: 24, offset: Offset(0, 8)),
          BoxShadow(
              color: Color(0x060A1F1D), blurRadius: 4, offset: Offset(0, 1)),
        ],
      );

  static BoxDecoration field({bool filled = false}) => BoxDecoration(
        color: filled ? AppColors.logoAqua : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: filled ? AppColors.teal.withValues(alpha: .30) : AppColors.border2,
        ),
      );
}

// ═══════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════
Color scoreColor(double score) {
  if (score >= 80) return AppColors.scoreHighFg;
  if (score >= 60) return AppColors.scoreMidFg;
  return AppColors.scoreLowFg;
}

Color scoreBgColor(double score) {
  if (score >= 80) return AppColors.scoreHighBg;
  if (score >= 60) return AppColors.scoreMidBg;
  return AppColors.scoreLowBg;
}

String initials(String name) {
  final clean = name.trim();
  if (clean.isEmpty) return '?';
  final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
  return parts.first.length >= 2
      ? parts.first.substring(0, 2).toUpperCase()
      : parts.first[0].toUpperCase();
}

List<Color> avatarColors = const [
  Color(0xFF0F6B62),
  Color(0xFF12A150),
  Color(0xFFE1483D),
  Color(0xFFE0A526),
  Color(0xFF6D4AB7),
  Color(0xFFDB4C8A),
];

Color avatarColor(String name) {
  final clean = name.trim();
  if (clean.isEmpty) return avatarColors.first;
  return avatarColors[clean.codeUnitAt(0) % avatarColors.length];
}
