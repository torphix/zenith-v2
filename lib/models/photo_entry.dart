/// A photo taken as evidence for a habit completion or task.
class PhotoEntry {
  final String localPath;
  final String? remotePath;
  final String habitName;
  final DateTime date;

  const PhotoEntry({
    required this.localPath,
    this.remotePath,
    required this.habitName,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'localPath': localPath,
        'remotePath': remotePath,
        'habitName': habitName,
        'date': date.toIso8601String(),
      };

  factory PhotoEntry.fromMap(Map<String, dynamic> map) => PhotoEntry(
        localPath: map['localPath'] ?? '',
        remotePath: map['remotePath'],
        habitName: map['habitName'] ?? '',
        date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      );
}
