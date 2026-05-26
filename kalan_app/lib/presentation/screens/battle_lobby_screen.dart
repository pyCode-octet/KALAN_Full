import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'create_challenge_screen.dart';
import 'notification_screen.dart';
import '../widgets/challenge_invitation_bottom_sheet.dart';
import '../blocs/notification/notification_bloc.dart';
import '../blocs/notification/notification_state.dart';
import '../../data/remote/supabase_service.dart';
import 'waiting_room_screen.dart';

class BattleLobbyScreen extends StatefulWidget {
  const BattleLobbyScreen({super.key});

  @override
  State<BattleLobbyScreen> createState() => _BattleLobbyScreenState();
}

class _BattleLobbyScreenState extends State<BattleLobbyScreen> {
  bool _isUserOnline(String? lastActiveStr) {
    if (lastActiveStr == null) return false;
    try {
      final lastActive = DateTime.parse(lastActiveStr);
      return DateTime.now().difference(lastActive).inMinutes < 5;
    } catch (e) { return false; }
  }

  Stream<List<Map<String, dynamic>>> _challengesStream(String status, {bool isInviter = false}) {
    final user = SupabaseService.currentUser;
    if (user == null) return Stream.value([]);
    
    final userId = user.id;
    return SupabaseService.client
        .from('battles')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((list) => list.where((row) => 
            (isInviter ? row['inviter_id'] == userId : row['invited_id'] == userId) && 
            row['status'] == status
        ).toList());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.client.from('users').stream(primaryKey: ['uuid']),
      builder: (context, userSnapshot) {
        final allUsers = userSnapshot.data ?? [];
        
        return Scaffold(
          backgroundColor: const Color(0xFFF5F2EA),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context), 
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        style: IconButton.styleFrom(backgroundColor: Colors.white),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text('ARENA', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20, color: const Color(0xFF2D6A2D))),
                          Text('${allUsers.where((u) => _isUserOnline(u['last_active'])).length} EN LIGNE', style: GoogleFonts.outfit(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const Spacer(),
                      BlocBuilder<NotificationBloc, NotificationState>(
                        builder: (context, ns) => IconButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                          icon: const Icon(Icons.notifications_none_rounded),
                          style: IconButton.styleFrom(backgroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF2D6A2D).withValues(alpha: 0.05)
                              )
                            ),
                            Image.asset(
                              'assets/images/epe.png',
                              height: 120,
                              errorBuilder: (_, __, ___) => const Text('⚔️', style: TextStyle(fontSize: 80)),
                            ),
                          ]
                        ),
                        const SizedBox(height: 16),
                        Text('GO ! TROUVE TON ADVERSAIRE', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('Défie les autres guerriers pour améliorer tes connaissances ! 🧠✨', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.black54, height: 1.4)),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity, height: 60,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateChallengeScreen())),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2D6A2D), 
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                            ),
                            child: Text('NOUVEAU DÉFI', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildChallengeSection('DÉFIS REÇUS', 'invitation_sent', allUsers),
                        const SizedBox(height: 24),
                        _buildChallengeSection('DÉFIS ENVOYÉS', 'invitation_sent', allUsers, isInviter: true),
                        const SizedBox(height: 30),
                        _buildChallengeSection('HISTORIQUE', 'finished', allUsers),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildChallengeSection(String title, String status, List<Map<String, dynamic>> allUsers, {bool isInviter = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black, letterSpacing: 1.2)),
        const SizedBox(height: 16),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _challengesStream(status, isInviter: isInviter),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                width: double.infinity, height: 60,
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Center(child: Text('Aucun défi...', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 12))),
              );
            }
            final challenges = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: challenges.length,
              itemBuilder: (context, i) {
                final challenge = challenges[i];
                
                // Résoudre le pseudo
                final String targetId = isInviter ? challenge['invited_id'] : challenge['inviter_id'];
                final targetUser = allUsers.firstWhere((u) => u['uuid'] == targetId, orElse: () => {});
                final String displayName = targetUser['pseudo'] ?? 'Joueur';

                return GestureDetector(
                  onTap: (!isInviter && status == 'invitation_sent') ? () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ChallengeInvitationBottomSheet(challenge: {...challenge, 'opponent_name': displayName}),
                    );
                  } : (isInviter && status == 'invitation_sent') ? () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => WaitingRoomScreen(
                      opponentName: displayName,
                      stake: challenge['xp_bet'] ?? 50,
                      battleId: challenge['id'],
                    )));
                  } : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white, 
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: const Color(0xFF2D6A2D).withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Center(child: Text('⚔️', style: TextStyle(fontSize: 20))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isInviter ? 'Défi envoyé à $displayName' : 'Défi de $displayName', 
                                style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black)
                              ),
                              const SizedBox(height: 2),
                              Text('Thème: ${challenge['theme']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text('${challenge['xp_bet'] ?? 50} XP', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFFF59E0B), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
