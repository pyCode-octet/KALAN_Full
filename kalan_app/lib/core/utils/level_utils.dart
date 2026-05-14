class LevelInfo {
  final String title;
  final int level;
  final int minPoints;
  final int maxPoints;

  LevelInfo({
    required this.title,
    required this.level,
    required this.minPoints,
    required this.maxPoints,
  });

  int get nextLevelPoints => maxPoints;

  double get progress {
    if (maxPoints == minPoints) return 1.0;
    return (maxPoints - minPoints) > 0 ? (maxPoints - minPoints).toDouble() : 0.0;
  }
}

class LevelUtils {
  static final List<LevelInfo> levels = [
    LevelInfo(title: 'Graine', level: 1, minPoints: 0, maxPoints: 100),
    LevelInfo(title: 'Baobab', level: 2, minPoints: 100, maxPoints: 300),
    LevelInfo(title: 'Feu de Brousse', level: 3, minPoints: 300, maxPoints: 600),
    LevelInfo(title: 'Griot', level: 4, minPoints: 600, maxPoints: 1000),
    LevelInfo(title: 'Masque', level: 5, minPoints: 1000, maxPoints: 1500),
    LevelInfo(title: 'Ancêtre', level: 6, minPoints: 1500, maxPoints: 999999),
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
