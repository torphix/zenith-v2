import 'dart:ui' show Color;

import 'package:cloud_firestore/cloud_firestore.dart';

import 'sub_skill.dart';

class StatSnapshot {
  /// Sub-skill XP tracking: subSkillId → accumulated XP.
  final Map<String, int> subSkillXP;

  /// Legacy stats for migration (body, mind, knowledge, heart, discipline, craft).
  /// Only present on old data before migration.
  final Map<String, int>? legacyStats;

  final int totalXP;
  final int level;
  final int currentStreak;
  final int longestStreak;
  final String archetypeId;
  final DateTime updatedAt;

  // ── Legacy stat names kept for migration ──

  static const _legacyDefaultSubSkills = {
    'body': ('physical_training', 'Physical Training', '💪', 'physical'),
    'mind': ('mindfulness', 'Mindfulness', '🧘', 'spiritual'),
    'knowledge': ('learning', 'Learning', '📖', 'intellectual'),
    'heart': ('connection', 'Connection', '💛', 'social'),
    'discipline': ('consistency', 'Consistency', '🔥', 'discipline'),
    'craft': ('creative_practice', 'Creative Practice', '✨', 'creative'),
  };

  /// Domain colors for charts — matches Domain.all colors.
  static const domainColors = {
    'physical': Color(0xFFD4A9B8),
    'creative': Color(0xFFA9C9B8),
    'intellectual': Color(0xFFB8A9C9),
    'social': Color(0xFFDEB8A6),
    'discipline': Color(0xFFD4A24E),
    'spiritual': Color(0xFFA9BCD4),
  };

  static const domainIcons = {
    'physical': '💪',
    'creative': '✨',
    'intellectual': '📖',
    'social': '💛',
    'discipline': '🔥',
    'spiritual': '🧘',
  };

  static const domainLabels = {
    'physical': 'Physical',
    'creative': 'Creative',
    'intellectual': 'Intellectual',
    'social': 'Social',
    'discipline': 'Discipline',
    'spiritual': 'Spiritual',
  };

  StatSnapshot({
    Map<String, int>? subSkillXP,
    this.legacyStats,
    this.totalXP = 0,
    this.level = 1,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.archetypeId = 'sage',
    DateTime? updatedAt,
  })  : subSkillXP = subSkillXP ?? {},
        updatedAt = updatedAt ?? DateTime.now();

  /// Whether this snapshot still has legacy stats that need migration.
  bool get needsMigration => legacyStats != null && legacyStats!.isNotEmpty;

  /// Compute domain totals by summing sub-skill XP per domain.
  /// Requires the list of sub-skills to map subSkillId → domain.
  Map<String, int> domainTotals(List<SubSkill> subSkills) {
    final totals = <String, int>{};
    for (final domain in Domain.domainIds) {
      totals[domain] = 0;
    }
    for (final entry in subSkillXP.entries) {
      final skill = subSkills.where((s) => s.id == entry.key).firstOrNull;
      if (skill != null) {
        totals[skill.domain] = (totals[skill.domain] ?? 0) + entry.value;
      }
    }
    return totals;
  }

  static int xpForLevel(int level) => (level * level * 50);

  double get levelProgress {
    final current = xpForLevel(level);
    final next = xpForLevel(level + 1);
    return ((totalXP - current) / (next - current)).clamp(0.0, 1.0);
  }

  /// Migrate legacy stats → sub-skill XP + create default sub-skills.
  /// Returns a tuple of (migrated snapshot, list of sub-skills to create).
  (StatSnapshot, List<SubSkill>) migrate() {
    if (!needsMigration) return (this, []);

    final newSubSkillXP = Map<String, int>.from(subSkillXP);
    final skillsToCreate = <SubSkill>[];

    for (final entry in legacyStats!.entries) {
      final defaults = _legacyDefaultSubSkills[entry.key];
      if (defaults != null && entry.value > 0) {
        final (id, name, icon, domain) = defaults;
        newSubSkillXP[id] = (newSubSkillXP[id] ?? 0) + entry.value;
        skillsToCreate.add(SubSkill(
          id: id,
          name: name,
          icon: icon,
          domain: domain,
          xp: entry.value,
        ));
      }
    }

    return (
      copyWith(subSkillXP: newSubSkillXP, clearLegacy: true),
      skillsToCreate,
    );
  }

  Map<String, dynamic> toMap() => {
        'subSkillXP': subSkillXP,
        if (legacyStats != null) 'stats': legacyStats,
        'totalXP': totalXP,
        'level': level,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'archetypeId': archetypeId,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory StatSnapshot.fromMap(Map<String, dynamic> map) {
    // Detect legacy format: has 'stats' but no 'subSkillXP'
    final hasLegacy = map.containsKey('stats') && map['stats'] is Map;
    final hasSubSkills =
        map.containsKey('subSkillXP') && map['subSkillXP'] is Map;

    return StatSnapshot(
      subSkillXP:
          hasSubSkills ? Map<String, int>.from(map['subSkillXP']) : null,
      legacyStats: hasLegacy ? Map<String, int>.from(map['stats']) : null,
      totalXP: map['totalXP'] ?? 0,
      level: map['level'] ?? 1,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      archetypeId: map['archetypeId'] ?? 'sage',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  StatSnapshot copyWith({
    Map<String, int>? subSkillXP,
    int? totalXP,
    int? level,
    int? currentStreak,
    int? longestStreak,
    String? archetypeId,
    bool clearLegacy = false,
  }) =>
      StatSnapshot(
        subSkillXP: subSkillXP ?? Map.from(this.subSkillXP),
        legacyStats: clearLegacy ? null : legacyStats,
        totalXP: totalXP ?? this.totalXP,
        level: level ?? this.level,
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        archetypeId: archetypeId ?? this.archetypeId,
        updatedAt: DateTime.now(),
      );
}
