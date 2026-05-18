import 'dart:ui' show Color;

import 'package:cloud_firestore/cloud_firestore.dart';

/// A dynamic, AI-generated skill tied to specific habits.
/// e.g. "Combat" for jiu jitsu, "Musical Ability" for piano practice.
class SubSkill {
  final String id;
  final String name;
  final String icon; // emoji
  final String domain; // one of Domain.all ids
  int xp;
  final DateTime createdAt;

  SubSkill({
    required this.id,
    required this.name,
    required this.icon,
    required this.domain,
    this.xp = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get level {
    int lvl = 1;
    while (xpForLevel(lvl + 1) <= xp) {
      lvl++;
    }
    return lvl;
  }

  double get levelProgress {
    final current = xpForLevel(level);
    final next = xpForLevel(level + 1);
    if (next == current) return 1.0;
    return ((xp - current) / (next - current)).clamp(0.0, 1.0);
  }

  static int xpForLevel(int level) => (level * level * 30);

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'domain': domain,
        'xp': xp,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SubSkill.fromMap(Map<String, dynamic> map) => SubSkill(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        icon: map['icon'] ?? '⭐',
        domain: map['domain'] ?? 'discipline',
        xp: map['xp'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  SubSkill copyWith({int? xp}) => SubSkill(
        id: id,
        name: name,
        icon: icon,
        domain: domain,
        xp: xp ?? this.xp,
        createdAt: createdAt,
      );
}

/// Fixed set of broad domains that sub-skills belong to.
class Domain {
  final String id;
  final String label;
  final String icon;
  final Color color;

  const Domain({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  static const all = [
    Domain(
      id: 'physical',
      label: 'Physical',
      icon: '💪',
      color: Color(0xFFD4A9B8),
    ),
    Domain(
      id: 'creative',
      label: 'Creative',
      icon: '✨',
      color: Color(0xFFA9C9B8),
    ),
    Domain(
      id: 'intellectual',
      label: 'Intellectual',
      icon: '📖',
      color: Color(0xFFB8A9C9),
    ),
    Domain(
      id: 'social',
      label: 'Social',
      icon: '💛',
      color: Color(0xFFDEB8A6),
    ),
    Domain(
      id: 'discipline',
      label: 'Discipline',
      icon: '🔥',
      color: Color(0xFFD4A24E),
    ),
    Domain(
      id: 'spiritual',
      label: 'Spiritual',
      icon: '🧘',
      color: Color(0xFFA9BCD4),
    ),
  ];

  static Domain? byId(String id) {
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  static const domainIds = [
    'physical',
    'creative',
    'intellectual',
    'social',
    'discipline',
    'spiritual',
  ];
}
