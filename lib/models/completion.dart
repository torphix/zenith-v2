import 'package:cloud_firestore/cloud_firestore.dart';

class Completion {
  final String id;
  final String habitId;
  final String programmeId;
  final DateTime date;
  final bool completed;
  final int? value; // for timed/counter habits
  final String? photoUrl;
  final String? note;
  final int xpEarned;
  final DateTime createdAt;

  Completion({
    required this.id,
    required this.habitId,
    required this.programmeId,
    required this.date,
    this.completed = false,
    this.value,
    this.photoUrl,
    this.note,
    this.xpEarned = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
        'id': id,
        'habitId': habitId,
        'programmeId': programmeId,
        'date': Timestamp.fromDate(date),
        'completed': completed,
        'value': value,
        'photoUrl': photoUrl,
        'note': note,
        'xpEarned': xpEarned,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Completion.fromMap(Map<String, dynamic> map) => Completion(
        id: map['id'] ?? '',
        habitId: map['habitId'] ?? '',
        programmeId: map['programmeId'] ?? '',
        date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        completed: map['completed'] ?? false,
        value: map['value'],
        photoUrl: map['photoUrl'],
        note: map['note'],
        xpEarned: map['xpEarned'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  Completion copyWith({
    bool? completed,
    int? value,
    String? photoUrl,
    String? note,
    int? xpEarned,
  }) =>
      Completion(
        id: id,
        habitId: habitId,
        programmeId: programmeId,
        date: date,
        completed: completed ?? this.completed,
        value: value ?? this.value,
        photoUrl: photoUrl ?? this.photoUrl,
        note: note ?? this.note,
        xpEarned: xpEarned ?? this.xpEarned,
        createdAt: createdAt,
      );
}
