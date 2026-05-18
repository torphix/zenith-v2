import 'package:cloud_firestore/cloud_firestore.dart';

/// A free-form task added via voice note or manually.
/// These are NOT programme habits – they represent one-off things
/// the user did or plans to do today.
class AdhocTask {
  final String id;
  final String title;
  final String? voiceNoteId;
  final bool completed;
  final String? subSkillId; // references SubSkill.id
  final int xp;
  final int? minutesSpent;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime date;
  final DateTime createdAt;
  final String? photoUrl;
  final String? mediaType; // 'photo' or 'video'

  AdhocTask({
    required this.id,
    required this.title,
    this.voiceNoteId,
    this.completed = false,
    this.subSkillId,
    this.xp = 5,
    this.minutesSpent,
    this.startTime,
    this.endTime,
    DateTime? date,
    DateTime? createdAt,
    this.photoUrl,
    this.mediaType,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  AdhocTask copyWith({
    bool? completed,
    int? minutesSpent,
    DateTime? startTime,
    DateTime? endTime,
    String? photoUrl,
    String? mediaType,
  }) =>
      AdhocTask(
        id: id,
        title: title,
        voiceNoteId: voiceNoteId,
        completed: completed ?? this.completed,
        subSkillId: subSkillId,
        xp: xp,
        minutesSpent: minutesSpent ?? this.minutesSpent,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        date: date,
        createdAt: createdAt,
        photoUrl: photoUrl ?? this.photoUrl,
        mediaType: mediaType ?? this.mediaType,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'voiceNoteId': voiceNoteId,
        'completed': completed,
        'subSkillId': subSkillId,
        'xp': xp,
        'minutesSpent': minutesSpent,
        'startTime':
            startTime != null ? Timestamp.fromDate(startTime!) : null,
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(createdAt),
        'photoUrl': photoUrl,
        'mediaType': mediaType,
      };

  factory AdhocTask.fromMap(Map<String, dynamic> map) => AdhocTask(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        voiceNoteId: map['voiceNoteId'],
        completed: map['completed'] ?? false,
        // Support both new 'subSkillId' and legacy 'primaryStat'
        subSkillId:
            map['subSkillId'] ?? _migratePrimaryStat(map['primaryStat']),
        xp: map['xp'] ?? 5,
        minutesSpent: map['minutesSpent'],
        startTime: (map['startTime'] as Timestamp?)?.toDate(),
        endTime: (map['endTime'] as Timestamp?)?.toDate(),
        date: (map['date'] as Timestamp?)?.toDate(),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        photoUrl: map['photoUrl'],
        mediaType: map['mediaType'],
      );

  static String? _migratePrimaryStat(String? primaryStat) {
    if (primaryStat == null) return null;
    const mapping = {
      'body': 'physical_training',
      'mind': 'mindfulness',
      'knowledge': 'learning',
      'heart': 'connection',
      'discipline': 'consistency',
      'craft': 'creative_practice',
    };
    return mapping[primaryStat];
  }
}
