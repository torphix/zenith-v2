import 'package:cloud_firestore/cloud_firestore.dart';

enum HabitType { checkbox, abstinence, timed, counter }

class Habit {
  final String id;
  final String programmeId;
  final String name;
  final HabitType type;
  final String subSkillId; // references SubSkill.id (e.g. 'combat', 'musical_ability')
  final int baseXP;
  final int? targetValue; // target minutes for timed, target count for counter
  final String? unit; // 'minutes', 'reps', 'pages', etc.
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.programmeId,
    required this.name,
    this.type = HabitType.checkbox,
    required this.subSkillId,
    this.baseXP = 10,
    this.targetValue,
    this.unit,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get typeLabel {
    switch (type) {
      case HabitType.checkbox:
        return 'Complete';
      case HabitType.abstinence:
        return 'Abstain';
      case HabitType.timed:
        return '${targetValue ?? 0} ${unit ?? 'min'}';
      case HabitType.counter:
        return '${targetValue ?? 0} ${unit ?? 'times'}';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'programmeId': programmeId,
        'name': name,
        'type': type.name,
        'subSkillId': subSkillId,
        'baseXP': baseXP,
        'targetValue': targetValue,
        'unit': unit,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'] ?? '',
        programmeId: map['programmeId'] ?? '',
        name: map['name'] ?? '',
        type: HabitType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => HabitType.checkbox,
        ),
        // Support both new 'subSkillId' and legacy 'primaryStat' field
        subSkillId: map['subSkillId'] ?? _migratePrimaryStat(map['primaryStat']),
        baseXP: map['baseXP'] ?? 10,
        targetValue: map['targetValue'],
        unit: map['unit'],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  /// Map legacy primaryStat values to default sub-skill IDs.
  static String _migratePrimaryStat(String? primaryStat) {
    const mapping = {
      'body': 'physical_training',
      'mind': 'mindfulness',
      'knowledge': 'learning',
      'heart': 'connection',
      'discipline': 'consistency',
      'craft': 'creative_practice',
    };
    return mapping[primaryStat] ?? 'consistency';
  }
}
