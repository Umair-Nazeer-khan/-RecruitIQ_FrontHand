# Project Audit Report: RecruitIQ

This document outlines critical failures, logical bugs, and structural improvements required for the RecruitIQ project.

---

## 🚩 1. Critical Failures (App Crashes)

### A. Android Build Failure (Core Library Desugaring)
*   **Issue:** The project uses `flutter_local_notifications`, which requires Java 8+ features. 
*   **Status:** Currently requires manual configuration in `android/app/build.gradle.kts`.
*   **Requirement:** `isCoreLibraryDesugaringEnabled = true` must be set, and the `desugar_jdk_libs` dependency must be added. Without this, the app will not build for Android.

### B. Firebase Initialization Safety
*   **Issue:** `main.dart` initializes Firebase inside a `try-catch`. If it fails (e.g., missing `google-services.json`), the app continues but will crash the moment any Firebase Auth/Firestore method is called.
*   **Requirement:** Implement a check to ensure Firebase is ready before allowing the user to reach the Login screen.

### C. Dependency Sync
*   **Issue:** `flutter_local_notifications` is commented out in `pubspec.yaml` but is used in the code.
*   **Requirement:** Uncomment the dependency and run `flutter pub get`.

---

## 🧠 2. Logical Bugs & Navigation Issues

### A. The "Ghost" Uploads Section
*   **File:** `lib/viewmodels/dashboard_viewmodel.dart` -> `UploadViewModel`
*   **Bug:** When a resume is successfully parsed, the candidate is **not** added to the `_files` list.
*   **Result:** The "Recently Uploaded" UI section remains empty even after successful uploads.

### B. Navigation Stack Leak
*   **Issue:** After a successful Login or Register, the app uses `Navigator.pushReplacement`. If the user presses the system back button on Android, the behavior can be inconsistent or allow them to "back" into a logged-out state.
*   **Requirement:** Use `Navigator.pushNamedAndRemoveUntil` to ensure the Auth screens are completely removed from memory once the user reaches the Dashboard.

### C. FCM Token Synchronization
*   **Issue:** The app retrieves an FCM token but does not consistently send it to the Django backend.
*   **Result:** The HR manager will not receive push notifications because the backend doesn't know which device belongs to which user.

---

## 🎨 3. Design & UI Improvements

### A. Layout Overflows
*   **Issue:** The Login and Register screens were prone to "Bottom Overflow" errors when the keyboard opened. 
*   **Status:** Partially fixed with `SingleChildScrollView`.
*   **Requirement:** All form-based screens must use scrolling containers to support different screen sizes.

### B. Theme Inconsistency
*   **Issue:** The app uses a Light Theme globally, but individual screens are hardcoded with Dark colors.
*   **Requirement:** Define a proper `ThemeData.dark()` in `main.dart` instead of hardcoding colors in every widget.

---

## 🧹 4. Extra / Dead Code
*   **`lib/services/firebase_service.dart`:** This file is currently 100% dead code (commented out). If the project is using the Django `ApiService` for everything, this file should be removed.
*   **Redundant Error Handling:** The project uses both `ToastHelper` (SnackBars) and inline error containers. Recommend choosing one standard for a cleaner UX.

---

## 🛠️ 5. Tasks for the Student
1. **Fix the Upload List:** Ensure the `UploadViewModel` updates the `_files` list after a successful parse.
2. **Environment Configuration:** Move the hardcoded API Base URL from `api_service.dart` to a central config file.
3. **FCM Linking:** Connect the Firebase FCM token retrieval to the Django "Update Profile" API.
4. **Build Fix:** Ensure `pubspec.yaml` and `build.gradle.kts` are in sync with the notification code.
