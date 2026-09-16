// // lib/services/firebase_service.dart
// // ─────────────────────────────────────────────────────────────
// //  Handles:
// //   1. Firebase Authentication (login / logout / register)
// //   2. FCM Token — saved to Firestore after login
// //   3. Firestore — save/read user data
// // ─────────────────────────────────────────────────────────────
//
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import '../models/models.dart';
//
// class FirebaseService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//
//   // ── Current Firebase user ──────────────────
//   User? get currentUser => _auth.currentUser;
//   Stream<User?> get authStateStream => _auth.authStateChanges();
//
//   // ══════════════════════════════════════════════
//   //  FCM TOKEN — get device push notification token
//   // ══════════════════════════════════════════════
//   Future<String?> getFCMToken() async {
//     try {
//       // Request permission (iOS requires this, Android doesn't)
//       NotificationSettings settings = await _fcm.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//
//       if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//         final token = await _fcm.getToken();
//         if (kDebugMode) {
//           print('📱 FCM Token: $token');
//         }
//         return token;
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('FCM token error: $e');
//       }
//     }
//     return null;
//   }
//
//   // ══════════════════════════════════════════════
//   //  REGISTER — create account + save to Firestore
//   // ══════════════════════════════════════════════
//   Future<UserModel?> register({
//     required String email,
//     required String password,
//     required String name,
//   }) async {
//     try {
//       // 1. Create Firebase Auth account
//       final cred = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       // 2. Get FCM push token for this device
//       final fcmToken = await getFCMToken();
//
//       // 3. Build user model
//       final user = UserModel(
//         uid: cred.user!.uid,
//         email: email,
//         name: name,
//         role: 'hr_manager',
//         fcmToken: fcmToken,
//         createdAt: DateTime.now(),
//       );
//
//       // 4. Save user to Firestore → users/{uid}
//       await _db
//           .collection('users')
//           .doc(cred.user!.uid)
//           .set(user.toFirestore());
//
//       return user;
//     } on FirebaseAuthException catch (e) {
//       throw _authError(e.code);
//     }
//   }
//
//   // ══════════════════════════════════════════════
//   //  LOGIN — sign in + refresh FCM token
//   // ══════════════════════════════════════════════
//   Future<UserModel?> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       // 1. Firebase sign in
//       final cred = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       // 2. Get fresh FCM token (can change over time)
//       final fcmToken = await getFCMToken();
//
//       // 3. Update FCM token in Firestore so backend can push notifications
//       if (fcmToken != null) {
//         await _db.collection('users').doc(cred.user!.uid).update({
//           'fcm_token': fcmToken,
//           'last_login': DateTime.now().toIso8601String(),
//         });
//       }
//
//       // 4. Fetch full user data from Firestore
//       final doc = await _db
//           .collection('users')
//           .doc(cred.user!.uid)
//           .get();
//
//       if (doc.exists) {
//         return UserModel.fromFirestore(doc.data()!, cred.user!.uid);
//       }
//     } on FirebaseAuthException catch (e) {
//       throw _authError(e.code);
//     }
//     return null;
//   }
//
//   // ══════════════════════════════════════════════
//   //  LOGOUT
//   // ══════════════════════════════════════════════
//   Future<void> logout() async {
//     // Clear FCM token from Firestore on logout
//     if (currentUser != null) {
//       await _db.collection('users').doc(currentUser!.uid).update({
//         'fcm_token': null,
//       });
//     }
//     await _auth.signOut();
//   }
//
//   // ══════════════════════════════════════════════
//   //  GET USER from Firestore
//   // ══════════════════════════════════════════════
//   Future<UserModel?> getUser(String uid) async {
//     final doc = await _db.collection('users').doc(uid).get();
//     if (doc.exists) {
//       return UserModel.fromFirestore(doc.data()!, uid);
//     }
//     return null;
//   }
//
//   // ══════════════════════════════════════════════
//   //  SAVE CANDIDATE to Firestore
//   // ══════════════════════════════════════════════
//   //
//   // ── API INTEGRATION ──────────────────────────
//   // After FastAPI parses the resume, save the result to Firestore
//   // for offline access and fast loading.
//   //
//   Future<void> saveCandidate(Candidate candidate) async {
//     await _db
//         .collection('candidates')
//         .doc(candidate.id.toString())
//         .set(candidate.toJson());
//   }
//
//   // ══════════════════════════════════════════════
//   //  UPDATE CANDIDATE STATUS (shortlist/accept/reject)
//   // ══════════════════════════════════════════════
//   Future<void> updateCandidateStatus(String candidateId, String status) async {
//     await _db
//         .collection('candidates')
//         .doc(candidateId)
//         .update({'status': status});
//   }
//
//   // ── Error messages ──────────────────────────
//   String _authError(String code) {
//     switch (code) {
//       case 'user-not-found':     return 'No account found with this email.';
//       case 'wrong-password':     return 'Incorrect password.';
//       case 'email-already-in-use': return 'Email already registered.';
//       case 'weak-password':      return 'Password must be at least 6 characters.';
//       case 'invalid-email':      return 'Please enter a valid email.';
//       case 'too-many-requests':  return 'Too many attempts. Try again later.';
//       default:                   return 'Authentication failed. Try again.';
//     }
//   }
// }
