import 'package:cloud_firestore/cloud_firestore.dart';

class Assessment {
  final String id;
  final Map<String, int> scores; // body, mind, relationships, career, finances, growth -> 1-10
  final DateTime createdAt;

  static const pillars = [
    'body',
    'mind',
    'relationships',
    'career',
    'finances',
    'growth',
  ];

  Assessment({
    required this.id,
    required this.scores,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'scores': scores,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Assessment.fromMap(Map<String, dynamic> map) => Assessment(
        id: map['id'] ?? '',
        scores: Map<String, int>.from(map['scores'] ?? {}),
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}
