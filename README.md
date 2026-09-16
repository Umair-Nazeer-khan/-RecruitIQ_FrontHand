# RecruitIQ network and notification update

This frontend update adds user-friendly network awareness without adding OS-level notification permissions.

## What is handled
- No Wi-Fi/mobile network: persistent offline banner + clear snackbar.
- Connection restored: one-time "back online" message.
- Slow server/API: timeout message.
- Server unreachable: human-readable message.
- 401: session expired / sign in again.
- 403: permission message.
- 404: resource not found.
- 429: too many requests.
- 5xx: server temporarily unavailable.
- Candidate status actions now report success only after the backend confirms the change.

## Dependency
Added `connectivity_plus: ^6.1.4`.

## Install
Replace the project `lib/` and `pubspec.yaml` with the included versions, then run:

```bash
flutter clean
flutter pub get
dart format lib
flutter analyze
flutter run
```

The app uses in-app SnackBar notifications so no extra notification permission is required.
