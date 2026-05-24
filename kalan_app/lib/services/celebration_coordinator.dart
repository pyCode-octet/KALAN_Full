import 'package:flutter/material.dart';

/// Un singleton pour coordonner les affichages de popups (niveaux, badges)
/// et éviter les superpositions désordonnées.
class CelebrationCoordinator {
  static GlobalKey<NavigatorState>? navigatorKey;
  static bool _isShowing = false;
  static final List<VoidCallback> _queue = [];

  /// Ajoute une action de célébration à la file d'attente ou l'exécute immédiatement.
  static void queueOrRun(VoidCallback action) {
    if (_isShowing) {
      _queue.add(action);
      debugPrint('[CelebrationCoordinator] Popup déjà en cours, ajout à la file.');
    } else {
      _runAction(action);
    }
  }

  static Future<void> _runAction(VoidCallback action) async {
    _isShowing = true;
    
    // Un petit délai pour s'assurer que le navigateur est prêt
    await Future.delayed(const Duration(milliseconds: 500));
    
    debugPrint('[CelebrationCoordinator] Exécution de la popup.');
    action();
  }

  /// Appelé par les popups quand elles sont fermées pour passer à la suivante.
  static void dismiss() {
    _isShowing = false;
    debugPrint('[CelebrationCoordinator] Popup fermée.');
    if (_queue.isNotEmpty) {
      final nextAction = _queue.removeAt(0);
      _runAction(nextAction);
    }
  }

  /// Helper pour naviguer/fermer de manière sécurisée via la clé globale
  static void pop() {
    if (navigatorKey?.currentState?.canPop() ?? false) {
      navigatorKey?.currentState?.pop();
      dismiss();
    }
  }

  /// Force l'affichage des popups en attente
  static void flushPending() {
    if (!_isShowing && _queue.isNotEmpty) {
      final nextAction = _queue.removeAt(0);
      _runAction(nextAction);
    }
  }
}
