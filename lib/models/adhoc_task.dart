import 'package:cloud_firestore/cloud_firestore.dart';

/// A free-form task added via voice note or manually.
/// These are NOT programme habits – they represent one-off things
/// the user did or plans to do today.
class AdhocTask {
  final String id;
  final String title;
  final String? voiceNoteId;
  final bool completed;
  final String? primaryStat;
  final int xp;
  final DateTime date;
  final DateTime createdAt;

  AdhocTask({
    required this.id,
    required this.title,
    this.voiceNoteId,
    this.completed = false,
    this.primaryStat,
    this.xp = 5,
    DateTime? date,
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  AdhocTask copyWith({bool? completed}) => AdhocTask(
        id: id,
        title: title,
        voiceNoteId: voiceNoteId,
        completed: completed ?? this.completed,
        primaryStat: primaryStat,
        xp: xp,
        date: date,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'voiceNoteId': voiceNoteId,
        'completed': completed,
        'primaryStat': primaryStat,
        'xp': xp,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory AdhocTask.fromMap(Map<String, dynamic> map) => AdhocTask(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        voiceNoteId: map['voiceNoteId'],
        completed: map['completed'] ?? false,
        primaryStat: map['primaryStat'],
        xp: map['xp'] ?? 5,
        date: (map['date'] as Timestamp?)?.toDate(),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
