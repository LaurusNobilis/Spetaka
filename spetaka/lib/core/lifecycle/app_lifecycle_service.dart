import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/acquittement/domain/pending_action_state.dart';

part 'app_lifecycle_service.g.dart';

/// Centralized app-lifecycle observer.
///
/// Only this class may use [WidgetsBindingObserver] for lifecycle events.
/// Feature code must subscribe via [appLifecycleServiceProvider].
///
/// ### Pending acquittement flow
/// 1. Before launching an external action (call/sms/whatsapp) the caller
///    invokes [setActionState] with a [PendingActionState].
/// 2. When the app resumes from background [didChangeAppLifecycleState] checks
///    the 30-minute expiry:
///    - Not expired → emits the state on [pendingActionStream].
///    - Expired     → silently discarded; manual fallback remains available.
/// 3. Features listen to [pendingActionStream] and open the acquittement sheet.
/// 4. The sheet calls [clearActionState] on open (AC3 — clear on open).
///
/// ### Legacy API (kept for backward compatibility)
/// [setPendingFriendId] / [pendingAcquittementFriendId] remain untouched so
/// existing tests continue to pass.
class AppLifecycleService with WidgetsBindingObserver {
  AppLifecycleService({required WidgetsBinding binding}) : _binding = binding {
    _binding.addObserver(this);
  }

  final WidgetsBinding _binding;

  // ── Legacy pending-friend-id ───────────────────────────────────────────
  String? _pendingFriendId;

  final _controller = StreamController<String?>.broadcast();
  final _lifecycleController = StreamController<AppLifecycleState>.broadcast();

  /// Emits the pending friend ID each time the app resumes and a friend ID is
  /// set.  Emits `null` when there is nothing pending (cleared state).
  Stream<String?> get pendingAcquittementFriendId => _controller.stream;

  /// Emits raw lifecycle events for cross-cutting services.
  ///
  /// Other services must NOT implement [WidgetsBindingObserver]; they should
  /// subscribe here instead.
  Stream<AppLifecycleState> get lifecycleStates => _lifecycleController.stream;

  /// Stores [friendId] as the next acquittement candidate.
  /// Pass `null` to clear (e.g. on rollback).
  void setPendingFriendId(String? friendId) {
    _pendingFriendId = friendId;
  }

  /// Returns the currently pending friend ID without consuming it.
  String? get currentPendingFriendId => _pendingFriendId;

  // ── Story 5-2: rich pending action state (with expiry + origin) ────────
  PendingActionState? _pendingActionState;

  final _actionController =
      StreamController<PendingActionState>.broadcast();

  /// Emits a [PendingActionState] each time the app resumes and a non-expired
  /// state exists.  Expired states are silently dropped (30-min guard).
  ///
  /// The sheet must call [clearActionState] once it is open (see AC3).
  Stream<PendingActionState> get pendingActionStream =>
      _actionController.stream;

  /// Stores [state] as the next acquittement candidate.
  ///
  /// Called by [ContactActionService] before leaving the app.
  /// Passing `null` rolls back (e.g. on launch failure).
  void setActionState(PendingActionState? state) {
    _pendingActionState = state;
  }

  /// Returns the current [PendingActionState] without consuming it.
  PendingActionState? get currentActionState => _pendingActionState;

  /// Clears the pending action state immediately.
  ///
  /// Must be called by [AcquittementSheet] when it opens (AC3).
  void clearActionState() {
    _pendingActionState = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleController.add(state);
    if (state == AppLifecycleState.resumed) {
      // ── Legacy: emit even if null so listeners can react to app resumes ─
      _controller.add(_pendingFriendId);
      _pendingFriendId = null;

      // ── Story 5-2: expiry guard ──────────────────────────────────────
      final actionState = _pendingActionState;
      _pendingActionState = null;
      if (actionState != null && !actionState.isExpired) {
        _actionController.add(actionState);
      }
      // Expired state: silently discarded (AC4).
    }
  }

  /// Detach observer and close the stream.  Must be called via [ref.onDispose].
  /// Safe to call multiple times (idempotent).
  void dispose() {
    _binding.removeObserver(this);
    if (!_controller.isClosed) {
      _controller.close();
    }
    if (!_lifecycleController.isClosed) {
      _lifecycleController.close();
    }
    if (!_actionController.isClosed) {
      _actionController.close();
    }
  }
}

/// keepAlive: prevents auto-disposal — losing pending state would break the
/// acquittement loop.
@Riverpod(keepAlive: true)
AppLifecycleService appLifecycleService(Ref ref) {
  final service = AppLifecycleService(binding: WidgetsBinding.instance);
  ref.onDispose(service.dispose);
  return service;
}
