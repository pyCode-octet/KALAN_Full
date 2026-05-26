import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/battle_service.dart';
import '../screens/waiting_room_screen.dart';
import '../../services/local_ai_service.dart';

class ChallengeInvitationBottomSheet extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final BattleService _battleService = BattleService();

  ChallengeInvitationBottomSheet({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    const Color indigo = Color(0xFF6366F1);
    const Color rose = Color(0xFFF43F5E);
    const Color gold = Color(0xFFF59E0B);
    const Color emerald = Color(0xFF10B981);

    final String opponentName = challenge['opponent_name'] ?? 'Un guerrier';
    final String theme = challenge['theme'] ?? 'Général';
    final int stake = challenge['xp_bet'] ?? 50;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: indigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: indigo, size: 40),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            'Défi Reçu !',
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
          
          const SizedBox(height: 12),
          
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 16, height: 1.5),
              children: [
                TextSpan(text: opponentName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                const TextSpan(text: ' te défie sur le thème '),
                TextSpan(text: theme, style: const TextStyle(fontWeight: FontWeight.bold, color: indigo)),
                const TextSpan(text: ' avec une mise de '),
                TextSpan(text: '$stake XP', style: const TextStyle(fontWeight: FontWeight.bold, color: gold)),
                const TextSpan(text: ' !'),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _battleService.refuseBattle(challenge['id']);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: rose,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text('REFUSER', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _battleService.acceptBattle(challenge['id']);
                    await _battleService.startGeneration(challenge['id']);
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WaitingRoomScreen(
                            opponentName: opponentName,
                            stake: stake,
                            battleId: challenge['id'],
                          ),
                        ),
                      );
                    }

                    try {
                      final localAI = LocalAIService();
                      final content = await localAI.generateBattleContent(theme: theme);
                      await _battleService.updateBattleContent(challenge['id'], content);
                    } catch (e) {
                      debugPrint('Erreur génération battle: $e');
                      await _battleService.refuseBattle(challenge['id']);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emerald,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text('ACCEPTER', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
