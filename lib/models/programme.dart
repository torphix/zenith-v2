import 'package:cloud_firestore/cloud_firestore.dart';

class Programme {
  final String id;
  final String name;
  final String theme;
  final String description;
  final List<String> focusPillars;
  final String coachingNote;
  final int programmeNumber;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime createdAt;

  Programme({
    required this.id,
    required this.name,
    required this.theme,
    required this.description,
    this.focusPillars = const [],
    this.coachingNote = '',
    this.programmeNumber = 1,
    DateTime? startDate,
    DateTime? endDate,
    this.isActive = true,
    DateTime? createdAt,
  })  : startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now().add(const Duration(days: 30)),
        createdAt = createdAt ?? DateTime.now();

  int get currentDay {
    final diff = DateTime.now().difference(startDate).inDays;
    return (diff + 1).clamp(1, 30);
  }

  double get progressPercent {
    final diff = DateTime.now().difference(startDate).inDays;
    return (diff / 30).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'theme': theme,
        'description': description,
        'focusPillars': focusPillars,
        'coachingNote': coachingNote,
        'programmeNumber': programmeNumber,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Programme.fromMap(Map<String, dynamic> map) => Programme(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        theme: map['theme'] ?? '',
        description: map['description'] ?? '',
        focusPillars: List<String>.from(map['focusPillars'] ?? []),
        coachingNote: map['coachingNote'] ?? '',
        programmeNumber: map['programmeNumber'] ?? 1,
        startDate: (map['startDate'] as Timestamp?)?.toDate(),
        endDate: (map['endDate'] as Timestamp?)?.toDate(),
        isActive: map['isActive'] ?? true,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  Programme copyWith({bool? isActive}) => Programme(
        id: id,
        name: name,
        theme: theme,
        description: description,
        focusPillars: focusPillars,
        coachingNote: coachingNote,
        programmeNumber: programmeNumber,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}
