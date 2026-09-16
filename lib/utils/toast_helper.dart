// lib/utils/toast_helper.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import 'app_constants.dart';

enum ToastType { success, error, info }

class ToastHelper {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.error,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Use the app-wide messenger (anchored above navigation) instead of
    // the calling screen's own context — this way a toast shown right
    // before navigating to a new screen (e.g. "Login successful" just
    // before switching to the dashboard) still displays properly instead
    // of being cut off when the screen underneath it is replaced.
    final messenger =
        rootScaffoldMessengerKey.currentState ?? ScaffoldMessenger.of(context);
    messenger.removeCurrentSnackBar();

    final Color accent = switch (type) {
      ToastType.success => AppColors.green,
      ToastType.error => AppColors.red,
      ToastType.info => AppColors.accent,
    };

    final IconData icon = switch (type) {
      ToastType.success => Icons.check_circle_rounded,
      ToastType.error => Icons.error_rounded,
      ToastType.info => Icons.info_rounded,
    };

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D24),
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: accent, width: 4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void global(
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.removeCurrentSnackBar();

    final Color accent = switch (type) {
      ToastType.success => AppColors.green,
      ToastType.error => AppColors.red,
      ToastType.info => AppColors.accent,
    };

    final IconData icon = switch (type) {
      ToastType.success => Icons.check_circle_rounded,
      ToastType.error => Icons.error_rounded,
      ToastType.info => Icons.info_rounded,
    };

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        padding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D24),
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: accent, width: 4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(.92),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: ToastType.error);

  static void info(BuildContext context, String message) =>
      show(context, message, type: ToastType.info);
}
