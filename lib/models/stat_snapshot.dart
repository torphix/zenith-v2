import 'package:cloud_firestore/cloud_firestore.dart';

class StatSnapshot {
  final Map<String, int> stats; // body, mind, knowledge, heart, discipline, craft
  final int totalXP;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final String archetypeId;
  final DateTime updatedAt;

  static const statNames = [
    'body',
    'mind',
    'knowledge',
    'heart',
    'discipline',
    'craft',
  ];

  static const statLabels = {
    'body': 'Body',
    'mind': 'Mind',
    'knowledge': 'Knowledge',
    'heart': 'Heart',
    'discipline': 'Discipline',
    'craft': 'Craft',
  };

  static const statIcons = {
    'body': '💪',
    'mind': '🧠',
    'knowledge': '📖',
    'heart': '❤️',
    'discipline': '🔥',
    'craft': '⚒️',
  };

  StatSnapshot({
    Map<String, int>? stats,
    this.totalXP = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.archetypeId = 'warrior',
    DateTime? updatedAt,
  })  : stats = stats ??
            {
              'body': 0,
              'mind': 0,
              'knowledge': 0,
              'heart': 0,
              'discipline': 0,
              'craft': 0,
            },
        updatedAt = updatedAt ?? DateTime.now();

  static int xpForLevel(int level) => (level * level * 50);

  double get levelProgress {
    final current = xpForLevel(level);
    final next = xpForLevel(level + 1);
    return ((totalXP - current) / (next - current)).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() => {
        'stats': stats,
        'totalXP': totalXP,
        'level': level,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'archetypeId': archetypeId,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory StatSnapshot.fromMap(Map<String, dynamic> map) => StatSnapshot(
        stats: Map<String, int>.from(map['stats'] ?? {}),
        totalXP: map['totalXP'] ?? 0,
        level: map['level'] ?? 1,
        currentStreak: map['currentStreak'] ?? 0,
        longestStreak: map['longestStreak'] ?? 0,
        archetypeId: map['archetypeId'] ?? 'warrior',
        updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      );

  StatSnapshot copyWith({
    Map<String, int>? stats,
    int? totalXP,
    int? level,
    int? currentStreak,
    int? longestStreak,
    String? archetypeId,
  }) =>
      StatSnapshot(
        stats: stats ?? Map.from(this.stats),
        totalXP: totalXP ?? this.totalXP,
        level: level ?? this.level,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        archetypeId: archetypeId ?? this.archetypeId,
        updatedAt: DateTime.now(),
      );
}
