import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lifecycle_service.g.dart';

/// Centralized app-lifecycle observer.
///
/// Only this class may use [WidgetsBindingObserver] for lifecycle events.
/// Feature code must subscribe via [appLifecycleServiceProvider].
///
/// ### Pending acquittement flow
/// 1. Before launching an external action (call/sms/whatsapp) the caller
///    invokes [setPendingFriendId] with the friend's ID.
/// 2. When the app resumes from background
///    [didChangeAppLifecycleState] emits that ID on
///    [pendingAcquittementFriendId] and clears it automatically.
/// 3. Features listen to the stream and open the acquittement sheet.
class AppLifecycleService with WidgetsBindingObserver {
  AppLifecycleService({required WidgetsBinding binding}) : _binding = binding {
    _binding.addObserver(this);
  }

  final WidgetsBinding _binding;
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleController.add(state);
    if (state == AppLifecycleState.resumed) {
      // Emit even if null so listeners can react to app resumes.
      _controller.add(_pendingFriendId);
      _pendingFriendId = null;
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
