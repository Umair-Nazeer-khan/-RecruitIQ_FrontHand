import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'app_constants.dart';
import 'toast_helper.dart';

/// App-wide network awareness.
///
/// Important: a Wi-Fi/mobile-data connection does not always mean that the
/// internet is reachable. Therefore API requests still have their own
/// timeout/network error handling. This class handles the visible connection
/// state and gives the user a clear message instead of a technical exception.
class NetworkStatusListener extends StatefulWidget {
  final Widget child;

  const NetworkStatusListener({required this.child, super.key});

  @override
  State<NetworkStatusListener> createState() => _NetworkStatusListenerState();
}

class _NetworkStatusListenerState extends State<NetworkStatusListener> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _offline = false;
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    _checkInitial();
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
  }

  Future<void> _checkInitial() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (!mounted) return;
      _updateState(_isOfflineResult(result), initial: true);
    } catch (_) {
      // Do not block app startup if the platform connectivity API fails.
    }
  }

  void _onChanged(List<ConnectivityResult> result) {
    if (!mounted) return;
    _updateState(_isOfflineResult(result));
  }

  bool _isOfflineResult(List<ConnectivityResult> result) =>
      result.isEmpty || result.every((item) => item == ConnectivityResult.none);

  void _updateState(bool offline, {bool initial = false}) {
    final wasOffline = _offline;
    _offline = offline;
    final firstCheck = !_hasChecked;
    _hasChecked = true;

    // Only announce transitions. This prevents repeated snackbars when the
    // operating system sends duplicate connectivity events.
    if (!initial && !firstCheck && offline != wasOffline) {
      if (offline) {
        ToastHelper.global(
          'No internet connection. Your data is safe; reconnect and try again.',
          type: ToastType.error,
          duration: const Duration(days: 1),
        );
      } else {
        ToastHelper.global(
          'You are back online. RecruitIQ is ready to continue.',
          type: ToastType.success,
        );
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_offline)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: IgnorePointer(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 14,
                        offset: Offset(0, 5),
                        color: Color(0x22000000),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Offline — check your internet connection',
                          style: AppText.label(12, color: Colors.white),
                        ),
                      ),
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
