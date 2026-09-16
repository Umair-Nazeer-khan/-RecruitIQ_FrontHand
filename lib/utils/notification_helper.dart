// // lib/utils/notification_helper.dart
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// /// Shows OS-level local notifications with clean, human-readable
// /// messages — never raw HTTP status codes or technical text.
// class NotificationHelper {
//   static final FlutterLocalNotificationsPlugin _plugin =
//   FlutterLocalNotificationsPlugin();
//   static bool _initialized = false;
//
//   static Future<void> init() async {
//     if (_initialized) return;
//
//     const androidSettings =
//     AndroidInitializationSettings('@mipmap/ic_launcher');
//     const iosSettings = DarwinInitializationSettings();
//     const settings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );
//
//     await _plugin.initialize(settings);
//
//     // Android 13+ (API 33) requires this runtime permission explicitly,
//     // separately from any Firebase/FCM permission — without it, calls to
//     // show() silently do nothing and no notification ever appears.
//     await _plugin
//         .resolvePlatformSpecificImplementation<
//         AndroidFlutterLocalNotificationsPlugin>()
//         ?.requestNotificationsPermission();
//
//     _initialized = true;
//   }
//
//   static Future<void> _show(String title, String body) async {
//     if (!_initialized) await init();
//
//     const androidDetails = AndroidNotificationDetails(
//       'recruitiq_channel',
//       'RecruitIQ Notifications',
//       channelDescription: 'Notifications for account and candidate actions',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//     const iosDetails = DarwinNotificationDetails();
//     const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
//
//     await _plugin.show(
//       DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       title,
//       body,
//       details,
//     );
//   }
//
//   // ── Clean, specific messages for each real event ──────────────
//   static Future<void> loginSuccess() =>
//       _show('Welcome back', 'You have successfully signed in to RecruitIQ.');
//
//   static Future<void> registerSuccess() =>
//       _show('Account created', 'Your RecruitIQ account is ready to use.');
//
//   static Future<void> resumeUploaded(String candidateName) => _show(
//       'Resume parsed', '$candidateName\'s resume was uploaded and parsed successfully.');
//
//   static Future<void> candidateShortlisted(String candidateName) =>
//       _show('Candidate shortlisted', '$candidateName has been added to your shortlist.');
//
//   static Future<void> matchComplete(int candidateCount) => _show(
//       'Matching complete', 'Ranked $candidateCount candidate(s) against your job requirements.');
// }
