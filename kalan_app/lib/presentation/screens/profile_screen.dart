import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/level_utils.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';
import '../blocs/user/user_state.dart';
import 'badges_screen.dart';
import 'login_screen.dart';
import '../../data/local/database_helper.dart';
import '../../data/remote/supabase_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserLoading) return const Center(child: CircularProgressIndicator());
            if (state is UserError) return Center(child: Text(state.message));
            if (state is UserLoaded) {
              final profile = state.profile;
              final stats = state.stats;
              final badges = state.badges;
              final points = profile['points'] as int? ?? 0;
              final levelInfo = LevelUtils.getLevelInfo(points);

              return Stack(
                children: [
                  // Watermark Flutter
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.03,
                      child: CustomPaint(
                        painter: FlutterWatermarkPainter(),
                      ),
                    ),
                  ),

                  SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildHeader(context, state.isOnline),
                          _buildIdentity(context, profile, levelInfo, points),
                          _buildStatsGrid(stats, profile),
                          _buildBadgesSection(context, badges),
                          // _buildPersonalInfoSection(context, profile),
                          _buildSettingsSection(context),
                          _buildLogoutButton(context),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isOnline) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildLogoSvg(),
              const SizedBox(width: 8),
              Text(
                'KALAN',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1A4D2E),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (!isOnline)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Hors ligne', style: TextStyle(color: Color(0xFFC2410C), fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoSvg() {
    return SizedBox(
      width: 28, height: 28,
      child: SvgPicture.string(
        '''
        <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
          <path d="M50 10 L80 50 L50 90 L20 50 Z" fill="#2E7D32" />
          <path d="M50 10 L65 50 L50 90 L35 50 Z" fill="#4CAF50" />
          <path d="M45 50 L55 50 L50 85 Z" fill="#5C3D1A" />
          <path d="M40 70 L60 70 L60 85 L40 85 Z" fill="#FBC02D" />
          <path d="M50 30 L60 50 L50 45 L40 50 Z" fill="#FBC02D" />
        </svg>
        ''',
      ),
    );
  }

  Widget _buildIdentity(BuildContext context, Map<String, dynamic> profile, LevelInfo levelInfo, int points) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE8D5A3), Color(0xFFC8956C)],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: ClipOval(child: _buildAvatarImage(profile)),
            ),
            Positioned(
              bottom: 4, right: 4,
              child: GestureDetector(
                onTap: () => _showAvatarPicker(context),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          profile['pseudo'] ?? 'Élève KALAN',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF111111)),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7F0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC8E6C9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('NIVEAU ${levelInfo.level}', style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Stack(
                children: [
                  Container(width: 120, height: 7, decoration: BoxDecoration(color: const Color(0xFFC8E6C9), borderRadius: BorderRadius.circular(6))),
                  Container(
                    width: 120 * (points / levelInfo.nextLevelPoints).clamp(0.0, 1.0),
                    height: 7, decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(6)),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Text('$points / ${levelInfo.nextLevelPoints} XP', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarImage(Map<String, dynamic> profile) {
    final avatarUrl = profile['avatar_url']?.toString();
    final avatarId = profile['avatar_id'];
    if (avatarUrl != null && avatarUrl.startsWith('http')) return Image.network(avatarUrl, fit: BoxFit.cover);
    if (avatarId != null) return Image.asset('assets/avatars/avatar$avatarId.png', fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildDefaultSvgAvatar());
    return _buildDefaultSvgAvatar();
  }

  Widget _buildDefaultSvgAvatar() {
    return SvgPicture.string(
      '''
      <svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
        <circle cx="50" cy="50" r="50" fill="#C07840" /><path d="M20 30 Q50 10 80 30 L80 40 Q50 20 20 40 Z" fill="#1A4D2E" /><circle cx="20" cy="50" r="5" fill="#FBC02D" /><circle cx="80" cy="50" r="5" fill="#FBC02D" /><path d="M30 70 Q50 90 70 70" fill="none" stroke="white" stroke-width="3" /><path d="M20 80 L80 80 L80 100 L20 100 Z" fill="#2E7D32" />
      </svg>
      ''',
      fit: BoxFit.cover,
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats, Map<String, dynamic> profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: [
          _buildStatCard('Fiches', (stats['deckCount'] ?? 0).toString(), const Color(0xFF7C3AED), Icons.description_outlined),
          _buildStatCard('Quiz', (stats['quizCount'] ?? 0).toString(), const Color(0xFFEA580C), Icons.help_outline_outlined),
          _buildStatCard('Réussite', '${((stats['avgScore'] ?? 0) * 100).toInt()}%', const Color(0xFF16A34A), Icons.trending_up),
          _buildStatCard('Série', '${profile['streak'] ?? 0}j', const Color(0xFFF97316), Icons.local_fire_department),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0EBE0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF111111), height: 1.1)),
                Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context, List<Map<String, dynamic>> userBadges) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Badges débloqués', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111111))),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesScreen())),
                child: const Text('Voir tout', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (userBadges.isEmpty)
            _buildEmptyState('Aucun badge pour le moment', Icons.emoji_events_outlined)
          else
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseHelper.instance.getAllBadges(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 80);
                final allBadges = snapshot.data!;
                final unlockedKeys = userBadges.map((b) => b['badge_key']).toSet();
                final earnedBadges = allBadges.where((b) => unlockedKeys.contains(b['id'])).toList();
                return Row(
                  children: earnedBadges.take(4).map((b) => Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: Column(
                      children: [
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: Color(b['color']).withValues(alpha: 0.15), shape: BoxShape.circle,
                            border: Border.all(color: Color(b['color']), width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(b['emoji'] ?? '🏆', style: const TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(height: 4),
                        Text(b['label'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF555555))),
                      ],
                    ),
                  )).toList(),
                );
              }
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context, Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mes infos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111111))),
              GestureDetector(
                onTap: () => _showEditProfileBottomSheet(context, profile),
                child: const Text('Modifier', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF0EBE0)),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.alternate_email, 'PSEUDO', profile['pseudo'] ?? '-', isFirst: true),
              _buildInfoRow(Icons.person_outline, 'NOM COMPLET', '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim().isEmpty ? '-' : '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim()),
              _buildInfoRow(Icons.school_outlined, 'ÉCOLE', profile['school_name'] ?? 'Non définie'),
              _buildInfoRow(Icons.class_outlined, 'CLASSE', profile['class_name'] ?? 'Non définie', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF5F5F0))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111111))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFD1D5DB)),
        ],
      ),
    );
  }

  void _showEditProfileBottomSheet(BuildContext context, Map<String, dynamic> profile) {
    final pseudoController = TextEditingController(text: profile['pseudo']);
    final firstNameController = TextEditingController(text: profile['first_name']);
    final lastNameController = TextEditingController(text: profile['last_name']);
    final schoolController = TextEditingController(text: profile['school_name']);
    String selectedClass = profile['class_name'] ?? '6ème';

    final classes = ['6ème', '5ème', '4ème', '3ème', '2nde', '1ère', 'Terminale', 'Autre'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Modifier mes infos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF111111))),
                const SizedBox(height: 24),
                _buildTextField('Pseudo', pseudoController, Icons.alternate_email),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField('Nom', lastNameController, Icons.person_outline)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Prénom', firstNameController, Icons.person_outline)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTextField('École', schoolController, Icons.school_outlined),
                const SizedBox(height: 16),
                const Text('Classe', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0EBE0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: classes.contains(selectedClass) ? selectedClass : 'Autre',
                      isExpanded: true,
                      onChanged: (val) => setState(() => selectedClass = val!),
                      items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                InkWell(
                  onTap: () {
                    if (pseudoController.text.trim().isEmpty || pseudoController.text.trim().length < 3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pseudo obligatoire (min 3 caractères)'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    // Dispatch Bloc Event
                    context.read<UserBloc>().add(UpdateUserProfile(
                      pseudo: pseudoController.text.trim(),
                      firstName: firstNameController.text.trim(),
                      lastName: lastNameController.text.trim(),
                      school: schoolController.text.trim(),
                      className: selectedClass,
                    ));

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Infos sauvegardées ✓'),
                        backgroundColor: Color(0xFF2E7D32),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('Sauvegarder', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF2E7D32)),
            hintText: 'Entrez votre $label',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0EBE0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF0EBE0))),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text('Paramètres', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111111))),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF0EBE0)))),
          child: Column(
            children: [
              const _SettingItem(icon: Icons.dark_mode_outlined, iconBg: Color(0xFFF3F4F6), title: 'Mode sombre', subtitle: 'Adapter l\'affichage', prefKey: 'dark_mode', defaultValue: false),
              const _SettingItem(icon: Icons.notifications_none_rounded, iconBg: Color(0xFFEEF2FF), title: 'Notifications', subtitle: 'Rappels de révisions', prefKey: 'notifications_enabled', defaultValue: true),
              const _SettingItem(icon: Icons.language_rounded, iconBg: Color(0xFFF0FDF4), title: 'Langue', subtitle: 'Français (Burkina Faso)', prefKey: 'language', defaultValue: true, isAction: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE0D8CC))),
      child: Column(children: [Icon(icon, color: Colors.grey.shade400, size: 32), const SizedBox(height: 8), Text(text, style: const TextStyle(color: Color(0xFF555555), fontSize: 12, fontWeight: FontWeight.w500))]),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout, color: Color(0xFFB91C1C), size: 18), SizedBox(width: 8), Text('Déconnexion', style: TextStyle(color: Color(0xFFB91C1C), fontSize: 14, fontWeight: FontWeight.w800))]),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Es-tu sûr de vouloir te déconnecter ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () async {
            await SupabaseService.client.auth.signOut();
            if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
          }, child: const Text('Déconnecter', style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choisir un avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final id = index + 1;
                  return GestureDetector(
                    onTap: () { context.read<UserBloc>().add(UpdateUserProfile(avatarId: id)); Navigator.pop(context); },
                    child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)), child: ClipOval(child: Image.asset('assets/avatars/avatar$id.png', fit: BoxFit.cover))),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingItem extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String prefKey;
  final bool defaultValue;
  final bool isAction;

  const _SettingItem({required this.icon, required this.iconBg, required this.title, required this.subtitle, required this.prefKey, required this.defaultValue, this.isAction = false});

  @override
  State<_SettingItem> createState() => _SettingItemState();
}

class _SettingItemState extends State<_SettingItem> {
  bool _value = false;

  @override
  void initState() { super.initState(); _loadPref(); }
  Future<void> _loadPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _value = prefs.getBool(widget.prefKey) ?? widget.defaultValue);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0EBE0)))),
      child: Row(
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: widget.iconBg, shape: BoxShape.circle), child: Icon(widget.icon, size: 18, color: const Color(0xFF111111))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111111))), const SizedBox(height: 1), Text(widget.subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)))])),
          if (widget.isAction) const Icon(Icons.chevron_right, size: 20, color: Color(0xFFD1D5DB))
          else GestureDetector(
            onTap: () async {
              final newValue = !_value;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(widget.prefKey, newValue);
              setState(() => _value = newValue);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200), width: 48, height: 28,
              decoration: BoxDecoration(color: _value ? const Color(0xFF2E7D32) : const Color(0xFFD1D5DB), borderRadius: BorderRadius.circular(14)),
              child: Stack(children: [AnimatedPositioned(duration: const Duration(milliseconds: 200), curve: Curves.easeIn, left: _value ? 23 : 3, top: 3, child: Container(width: 22, height: 22, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 1))])))]),
            ),
          ),
        ],
      ),
    );
  }
}

class FlutterWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.fill;
    final double w = size.width;
    final double h = size.height;

    void drawLogo(double x, double y, double scale) {
      final path = Path();
      path.moveTo(x + 40 * scale, y + 0 * scale);
      path.lineTo(x + 100 * scale, y + 60 * scale);
      path.lineTo(x + 70 * scale, y + 90 * scale);
      path.lineTo(x + 10 * scale, y + 30 * scale);
      path.close();

      path.moveTo(x + 70 * scale, y + 30 * scale);
      path.lineTo(x + 100 * scale, y + 60 * scale);
      path.lineTo(x + 70 * scale, y + 90 * scale);
      path.lineTo(x + 40 * scale, y + 60 * scale);
      path.close();
      canvas.drawPath(path, paint);
    }

    drawLogo(w * 0.1, h * 0.2, 0.8);
    drawLogo(w * 0.6, h * 0.5, 1.2);
    drawLogo(w * 0.2, h * 0.8, 0.6);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
