import 'package:cloud_firestore/cloud_firestore.dart';

import 'photo_entry.dart';

class WrapData {
  final String id;
  final String type; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime date;
  final double completionRate;
  final Map<String, int> statsGained; // subSkillId -> xp gained
  final List<String> skillsLeveledUp;
  final String archetypeId;
  final String? archetypeShift; // if archetype changed
  final String coachNote;
  final List<String> highlights;
  final List<String> photoUrls;
  final List<PhotoEntry> photoEntries; // enriched photo data for montage
  final Map<String, int>? previousStats; // sub-skill XP snapshot before this period
  final int dayNumber; // which day of the 30-day programme
  final int totalXP;
  final int habitsCompleted;
  final int habitsTotal;
  final DateTime createdAt;

  WrapData({
    required this.id,
    required this.type,
    required this.date,
    this.completionRate = 0,
    this.statsGained = const {},
    this.skillsLeveledUp = const [],
    this.archetypeId = 'sage',
    this.archetypeShift,
    this.coachNote = '',
    this.highlights = const [],
    this.photoUrls = const [],
    this.photoEntries = const [],
    this.previousStats,
    this.dayNumber = 1,
    this.totalXP = 0,
    this.habitsCompleted = 0,
    this.habitsTotal = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'date': Timestamp.fromDate(date),
        'completionRate': completionRate,
        'statsGained': statsGained,
        'skillsLeveledUp': skillsLeveledUp,
        'archetypeId': archetypeId,
        'archetypeShift': archetypeShift,
        'coachNote': coachNote,
        'highlights': highlights,
        'photoUrls': photoUrls,
        'photoEntries': photoEntries.map((e) => e.toMap()).toList(),
        'previousStats': previousStats,
        'dayNumber': dayNumber,
        'totalXP': totalXP,
        'habitsCompleted': habitsCompleted,
        'habitsTotal': habitsTotal,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory WrapData.fromMap(Map<String, dynamic> map) => WrapData(
        id: map['id'] ?? '',
        type: map['type'] ?? 'daily',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        completionRate: (map['completionRate'] ?? 0).toDouble(),
        statsGained: Map<String, int>.from(map['statsGained'] ?? {}),
        skillsLeveledUp: List<String>.from(map['skillsLeveledUp'] ?? []),
        archetypeId: map['archetypeId'] ?? 'sage',
        archetypeShift: map['archetypeShift'],
        coachNote: map['coachNote'] ?? '',
        highlights: List<String>.from(map['highlights'] ?? []),
        photoUrls: List<String>.from(map['photoUrls'] ?? []),
        photoEntries: (map['photoEntries'] as List<dynamic>?)
                ?.map((e) => PhotoEntry.fromMap(Map<String, dynamic>.from(e)))
                .toList() ??
            [],
        previousStats: map['previousStats'] != null
            ? Map<String, int>.from(map['previousStats'])
            : null,
        dayNumber: map['dayNumber'] ?? 1,
        totalXP: map['totalXP'] ?? 0,
        habitsCompleted: map['habitsCompleted'] ?? 0,
        habitsTotal: map['habitsTotal'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
