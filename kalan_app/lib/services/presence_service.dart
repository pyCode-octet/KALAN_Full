import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/remote/supabase_service.dart';

class PresenceService {
  static Timer? _heartbeatTimer;

  /// Démarre la mise à jour automatique de la présence
  static void startHeartbeat() {
    _heartbeatTimer?.cancel();
    
    // Mettre à jour immédiatement à la connexion
    _updatePresence();

    // Puis toutes les 5 minutes
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _updatePresence();
    });
  }

  /// Arrête le heartbeat (ex: à la déconnexion)
  static void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  static Future<void> _updatePresence() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('users')
          .update({'last_active': DateTime.now().toIso8601String()})
          .eq('uuid', user.id);
      // ignore: avoid_print
      print('Presence: last_active updated for ${user.id}');
    } catch (e) {
      // ignore: avoid_print
      print('Presence Error: $e');
    }
  }
}
