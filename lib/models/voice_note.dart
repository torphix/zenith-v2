import 'package:cloud_firestore/cloud_firestore.dart';

class VoiceNote {
  final String id;
  final String? programmeId;
  final String audioUrl;
  final String? transcript;
  final DateTime createdAt;

  VoiceNote({
    required this.id,
    this.programmeId,
    required this.audioUrl,
    this.transcript,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'programmeId': programmeId,
        'audioUrl': audioUrl,
        'transcript': transcript,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory VoiceNote.fromMap(Map<String, dynamic> map) => VoiceNote(
        id: map['id'] ?? '',
        programmeId: map['programmeId'],
        audioUrl: map['audioUrl'] ?? '',
        transcript: map['transcript'],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );
}
