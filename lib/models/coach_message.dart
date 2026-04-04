class CoachMessage {
  final String role; // 'user' or 'coach'
  final String content;
  final DateTime timestamp;

  CoachMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CoachMessage.fromMap(Map<String, dynamic> map) => CoachMessage(
        role: map['role'] ?? 'coach',
        content: map['content'] ?? '',
        timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      );
}
