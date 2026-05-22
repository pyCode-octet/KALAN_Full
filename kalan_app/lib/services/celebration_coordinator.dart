import 'package:flutter/material.dart';
import 'celebration_gate.dart';

/// File d'attente des popups de célébration (niveau, badge) pendant le quiz.
class CelebrationCoordinator {
  static GlobalKey<NavigatorState>? navigatorKey;
  static final List<VoidCallback> _pending = [];

  static void queueOrRun(VoidCallback action) {
    if (CelebrationGate.isSuppressed) {
      _pending.add(action);
      return;
    }
    _schedule(action);
  }

  static void flushPending() {
    if (_pending.isEmpty) return;
    final pending = List<VoidCallback>.from(_pending);
    _pending.clear();
    for (var i = 0; i < pending.length; i++) {
      Future.delayed(Duration(milliseconds: i * 550), () => _schedule(pending[i]));
    }
  }

  static void _schedule(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey?.currentContext;
      if (ctx != null && ctx.mounted) {
        action();
      }
    });
  }
}
