import 'package:cloud_firestore/cloud_firestore.dart';

class WrapData {
  final String id;
  final String type; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime date;
  final double completionRate;
  final Map<String, int> statsGained; // stat -> xp gained
  final List<String> skillsLeveledUp;
  final String archetypeId;
  final String? archetypeShift; // if archetype changed
  final String coachNote;
  final List<String> highlights;
  final List<String> photoUrls;
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
    this.archetypeId = 'warrior',
    this.archetypeShift,
    this.coachNote = '',
    this.highlights = const [],
    this.photoUrls = const [],
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
        archetypeId: map['archetypeId'] ?? 'warrior',
        archetypeShift: map['archetypeShift'],
        coachNote: map['coachNote'] ?? '',
        highlights: List<String>.from(map['highlights'] ?? []),
        photoUrls: List<String>.from(map['photoUrls'] ?? []),
        totalXP: map['totalXP'] ?? 0,
        habitsCompleted: map['habitsCompleted'] ?? 0,
        habitsTotal: map['habitsTotal'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
