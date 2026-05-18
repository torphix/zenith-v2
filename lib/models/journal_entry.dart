import 'package:cloud_firestore/cloud_firestore.dart';

/// A journal entry from a morning or evening reflection prompt.
class JournalEntry {
  final String id;
  final String type; // 'morning' or 'evening'
  final String prompt;
  final String response;
  final DateTime date;
  final DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.type,
    required this.prompt,
    required this.response,
    DateTime? date,
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'prompt': prompt,
        'response': response,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory JournalEntry.fromMap(Map<String, dynamic> map) => JournalEntry(
        id: map['id'] as String,
        type: map['type'] as String,
        prompt: map['prompt'] as String,
        response: map['response'] as String,
        date: (map['date'] as Timestamp).toDate(),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
      );
}
