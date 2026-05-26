class Battle {
  final String id;
  final String inviterId;
  final String invitedId;
  final String status;
  final String? theme;
  final int xpBet;
  final DateTime createdAt;
  final DateTime? phaseStartTime;
  final Map<String, dynamic>? flashcards;
  final Map<String, dynamic>? quizQuestions;
  final int currentQuestionIndex;
  final int inviterScore;
  final int invitedScore;
  final String? realTheme;
  final String? turnUserId;
  final String? winnerId;

  Battle({
    required this.id,
    required this.inviterId,
    required this.invitedId,
    required this.status,
    this.theme,
    required this.xpBet,
    required this.createdAt,
    this.phaseStartTime,
    this.flashcards,
    this.quizQuestions,
    required this.currentQuestionIndex,
    required this.inviterScore,
    required this.invitedScore,
    this.realTheme,
    this.turnUserId,
    this.winnerId,
  });

  factory Battle.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as Map<String, dynamic>?;
    return Battle(
      id: json['id'],
      inviterId: json['inviter_id'],
      invitedId: json['invited_id'],
      status: json['status'],
      theme: json['theme'],
      xpBet: json['xp_bet'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      phaseStartTime: json['phase_start_time'] != null ? DateTime.parse(json['phase_start_time']) : null,
      flashcards: content?['flashcards'],
      quizQuestions: content?['quizzes'] ?? content?['quiz_questions'],
      currentQuestionIndex: json['current_question_index'] ?? 0,
      inviterScore: json['inviter_score'] ?? 0,
      invitedScore: json['invited_score'] ?? 0,
      realTheme: json['real_theme'],
      turnUserId: json['turn_user_id'],
      winnerId: json['winner_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inviter_id': inviterId,
      'invited_id': invitedId,
      'status': status,
      'theme': theme,
      'xp_bet': xpBet,
      'current_question_index': currentQuestionIndex,
      'inviter_score': inviterScore,
      'invited_score': invitedScore,
      'real_theme': realTheme,
      'turn_user_id': turnUserId,
      'winner_id': winnerId,
    };
  }
}
