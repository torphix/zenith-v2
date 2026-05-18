import 'package:cloud_firestore/cloud_firestore.dart';

class QuestPhase {
  final String name;
  final String description;
  final List<String> dailyActions;
  final String milestone;
  final int durationDays;
  final bool completed;

  QuestPhase({
    required this.name,
    required this.description,
    this.dailyActions = const [],
    required this.milestone,
    this.durationDays = 7,
    this.completed = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'dailyActions': dailyActions,
        'milestone': milestone,
        'durationDays': durationDays,
        'completed': completed,
      };

  factory QuestPhase.fromMap(Map<String, dynamic> map) => QuestPhase(
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        dailyActions: List<String>.from(map['dailyActions'] ?? []),
        milestone: map['milestone'] ?? '',
        durationDays: map['durationDays'] ?? 7,
        completed: map['completed'] ?? false,
      );
}

class Quest {
  final String id;
  final String programmeId;
  final String title;
  final String description;
  final String subSkillId; // references SubSkill.id
  final List<QuestPhase> phases;
  final int currentPhase;
  final DateTime createdAt;

  Quest({
    required this.id,
    required this.programmeId,
    required this.title,
    required this.description,
    required this.subSkillId,
    this.phases = const [],
    this.currentPhase = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progressPercent {
    if (phases.isEmpty) return 0;
    final done = phases.where((p) => p.completed).length;
    return done / phases.length;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'programmeId': programmeId,
        'title': title,
        'description': description,
        'subSkillId': subSkillId,
        'phases': phases.map((p) => p.toMap()).toList(),
        'currentPhase': currentPhase,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Quest.fromMap(Map<String, dynamic> map) => Quest(
        id: map['id'] ?? '',
        programmeId: map['programmeId'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        // Support both new 'subSkillId' and legacy 'primaryStat'
        subSkillId: map['subSkillId'] ?? _migratePrimaryStat(map['primaryStat']),
        phases: (map['phases'] as List?)
                ?.map((p) => QuestPhase.fromMap(p as Map<String, dynamic>))
                .toList() ??
            [],
        currentPhase: map['currentPhase'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

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
