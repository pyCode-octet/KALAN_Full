class LevelInfo {
  final String title;
  final int level;
  final int minPoints;
  final int maxPoints;
  final String icon;

  LevelInfo({
    required this.title,
    required this.level,
    required this.minPoints,
    required this.maxPoints,
    required this.icon,
  });

  int get nextLevelPoints => maxPoints;

  double get progress {
    if (maxPoints == minPoints) return 1.0;
    final p = (maxPoints - minPoints) > 0 ? (maxPoints - minPoints).toDouble() : 0.0;
    return p;
  }
}

class LevelUtils {
  static final List<LevelInfo> levels = [
    LevelInfo(title: 'Graine', level: 1, minPoints: 0, maxPoints: 100, icon: '🌱'),
    LevelInfo(title: 'Baobab', level: 2, minPoints: 100, maxPoints: 300, icon: '🌳'),
    LevelInfo(title: 'Feu de Brousse', level: 3, minPoints: 300, maxPoints: 700, icon: '🔥'),
    LevelInfo(title: 'Griot', level: 4, minPoints: 700, maxPoints: 1200, icon: '🪕'),
    LevelInfo(title: 'Masque', level: 5, minPoints: 1200, maxPoints: 2000, icon: '🎭'),
    LevelInfo(title: 'Ancêtre', level: 6, minPoints: 2000, maxPoints: 999999, icon: '✨'),
  ];

  static LevelInfo getLevelInfo(int points) {
    for (var i = levels.length - 1; i >= 0; i--) {
      if (points >= levels[i].minPoints) {
        return levels[i];
      }
    }
    return levels.first;
  }

  static String getLevelTitle(int level) {
    if (level < 1) return levels[0].title;
    if (level > levels.length) return levels.last.title;
    return levels[level - 1].title;
  }
}
