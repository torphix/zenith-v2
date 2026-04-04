import 'package:cloud_firestore/cloud_firestore.dart';

enum HabitType { checkbox, abstinence, timed, counter }

class Habit {
  final String id;
  final String programmeId;
  final String name;
  final HabitType type;
  final String primaryStat; // body, mind, knowledge, heart, discipline, craft
  final int baseXP;
  final int? targetValue; // target minutes for timed, target count for counter
  final String? unit; // 'minutes', 'reps', 'pages', etc.
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.programmeId,
    required this.name,
    this.type = HabitType.checkbox,
    required this.primaryStat,
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
        'primaryStat': primaryStat,
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
        primaryStat: map['primaryStat'] ?? 'discipline',
        baseXP: map['baseXP'] ?? 10,
        targetValue: map['targetValue'],
        unit: map['unit'],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
