import 'package:cloud_firestore/cloud_firestore.dart';

class Completion {
  final String id;
  final String habitId;
  final String programmeId;
  final DateTime date;
  final bool completed;
  final int? value; // for timed/counter habits
  final DateTime? startTime; // when the task was started/logged
  final DateTime? endTime; // startTime + duration
  final String? photoUrl; // local file path for photo/video
  final String? mediaType; // 'photo' or 'video'
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
    this.startTime,
    this.endTime,
    this.photoUrl,
    this.mediaType,
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
        'startTime':
            startTime != null ? Timestamp.fromDate(startTime!) : null,
        'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
        'photoUrl': photoUrl,
        'mediaType': mediaType,
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
        startTime: (map['startTime'] as Timestamp?)?.toDate(),
        endTime: (map['endTime'] as Timestamp?)?.toDate(),
        photoUrl: map['photoUrl'],
        mediaType: map['mediaType'],
        note: map['note'],
        xpEarned: map['xpEarned'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  Completion copyWith({
    bool? completed,
    int? value,
    DateTime? startTime,
    DateTime? endTime,
    String? photoUrl,
    String? mediaType,
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
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        photoUrl: photoUrl ?? this.photoUrl,
        mediaType: mediaType ?? this.mediaType,
        note: note ?? this.note,
        xpEarned: xpEarned ?? this.xpEarned,
        createdAt: createdAt,
      );
}
