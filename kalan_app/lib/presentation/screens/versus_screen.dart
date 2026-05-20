import 'dart:async';
import 'package:flutter/material.dart';

class VersusScreen extends StatefulWidget {
  const VersusScreen({super.key});

  @override
  State<VersusScreen> createState() => _VersusScreenState();
}

class _VersusScreenState extends State<VersusScreen> with SingleTickerProviderStateMixin {
  int _wagerXp = 50;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _pulseController;

  // Mock list of friends for visualization
  final List<Map<String, dynamic>> _mockFriends = [
    {'pseudo': 'Yaya_Dev', 'avatar': 'assets/avatars/avatar2.png', 'status': 'online', 'xp': 1420},
    {'pseudo': 'Fatou_K', 'avatar': 'assets/avatars/avatar3.png', 'status': 'online', 'xp': 950},
    {'pseudo': 'Issa_Kalan', 'avatar': 'assets/avatars/avatar4.png', 'status': 'in_game', 'xp': 2100},
    {'pseudo': 'Mariam_Study', 'avatar': 'assets/avatars/avatar1.png', 'status': 'offline', 'xp': 680},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  ImageProvider _getAvatarImage(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return const AssetImage('assets/avatars/avatar1.png');
    }
    if (avatar.startsWith('assets/')) {
      return AssetImage(avatar);
    }
    return NetworkImage(avatar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4EC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D5C14)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mode Versus', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2D5C14))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 25),
            _buildWagerSelector(),
            const SizedBox(height: 25),
            _buildSearchBox(),
            const SizedBox(height: 20),
            const Text(
              'Tes amis',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2A1A08)),
            ),
            const SizedBox(height: 10),
            _buildFriendsList(),
            const SizedBox(height: 25),
            _buildQuickMatchButton(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('⚔️', style: TextStyle(fontSize: 32)),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Défis en temps réel !',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2A1A08)),
                ),
                SizedBox(height: 4),
                Text(
                  'Mise tes points XP, invite un ami à réviser, et remporte la totalité des points misés en finissant premier au quiz !',
                  style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.4, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWagerSelector() {
    final List<int> presetWagers = [50, 100, 200, 500];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisis ta mise (XP)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2A1A08)),
        ),
        const SizedBox(height: 12),
        Row(
          children: presetWagers.map((wager) {
            final isSelected = _wagerXp == wager;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: wager == presetWagers.first ? 0 : 4,
                  right: wager == presetWagers.last ? 0 : 4,
                ),
                child: GestureDetector(
                  onTap: () => setState(() => _wagerXp = wager),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF2D5C14) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : const Color(0xFFE0D8CC),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: const Color(0xFF2D5C14).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Text(
                      '$wager XP',
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF2A1A08),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Rechercher le pseudo de ton ami...",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2D5C14)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.03)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.03)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2D5C14), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _mockFriends.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final friend = _mockFriends[index];
          final status = friend['status'] as String;

          Color statusColor;
          String statusText;
          Widget actionButton;

          if (status == 'online') {
            statusColor = Colors.green;
            statusText = 'En ligne';
            actionButton = ElevatedButton(
              onPressed: () {
                _showInviteSentDialog(friend['pseudo']);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5C14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Défier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
            );
          } else if (status == 'in_game') {
            statusColor = Colors.orange;
            statusText = 'En partie';
            actionButton = OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              child: const Text('Occupé', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, fontSize: 11)),
            );
          } else {
            statusColor = Colors.grey;
            statusText = 'Hors-ligne';
            actionButton = OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              child: const Text('Inviter', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, fontSize: 11)),
            );
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(child: Image(image: _getAvatarImage(friend['avatar']), fit: BoxFit.cover)),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              friend['pseudo'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2A1A08)),
            ),
            subtitle: Row(
              children: [
                Text(statusText, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                Text('•', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                const SizedBox(width: 8),
                Text('${friend['xp']} XP', style: const TextStyle(fontSize: 11, color: Color(0xFF5A8A20), fontWeight: FontWeight.w700)),
              ],
            ),
            trailing: actionButton,
          );
        },
      ),
    );
  }

  Widget _buildQuickMatchButton() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.98, end: 1.02).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D2008), Color(0xFF5C3317)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3D2008).withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: _showMatchmakingDialog,
          borderRadius: BorderRadius.circular(20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flash_on_rounded, color: Color(0xFFFAC775), size: 24),
              SizedBox(width: 10),
              Text(
                'Matchmaking Rapide',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteSentDialog(String opponent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('⚔️', style: TextStyle(fontSize: 22)),
            SizedBox(width: 10),
            Text('Défi envoyé !', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          'Une invitation de duel (mise de $_wagerXp XP) a été envoyée à $opponent. Dès qu\'il accepte, la partie commence !',
          style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: Color(0xFF2D5C14), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMatchmakingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MatchmakingDialog(wagerXp: _wagerXp),
    );
  }
}

class _MatchmakingDialog extends StatefulWidget {
  final int wagerXp;
  const _MatchmakingDialog({required this.wagerXp});

  @override
  State<_MatchmakingDialog> createState() => _MatchmakingDialogState();
}

class _MatchmakingDialogState extends State<_MatchmakingDialog> {
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2D5C14)),
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recherche d\'adversaire...',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2A1A08)),
            ),
            const SizedBox(height: 8),
            Text(
              'Mise : ${widget.wagerXp} XP • Temps écoulé : $_seconds s',
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nous te mettons en relation avec un autre élève connecté pour un duel de révision !',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler la recherche', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
