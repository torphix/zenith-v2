import 'package:flutter/material.dart';

class Archetype {
  final String id;
  final String name;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final Map<String, double> statWeights; // which stats define this archetype

  const Archetype({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.statWeights,
  });

  static const List<Archetype> all = [
    Archetype(
      id: 'warrior',
      name: 'Warrior',
      title: 'The Warrior',
      description:
          'Forged through discipline and physical mastery. You push your body and mind to the edge, embracing discomfort as the path to strength.',
      icon: '⚔️',
      color: Color(0xFFC27070),
      statWeights: {'body': 0.4, 'discipline': 0.4, 'heart': 0.2},
    ),
    Archetype(
      id: 'scholar',
      name: 'Scholar',
      title: 'The Scholar',
      description:
          'Driven by an insatiable thirst for knowledge. You sharpen your mind daily, seeking wisdom in every experience.',
      icon: '📚',
      color: Color(0xFF7B68AE),
      statWeights: {'knowledge': 0.4, 'mind': 0.4, 'craft': 0.2},
    ),
    Archetype(
      id: 'creator',
      name: 'Creator',
      title: 'The Creator',
      description:
          'You bring ideas to life. Through craft and creativity, you build things that didn\'t exist before.',
      icon: '🔨',
      color: Color(0xFFD4A24E),
      statWeights: {'craft': 0.4, 'knowledge': 0.3, 'mind': 0.3},
    ),
    Archetype(
      id: 'sage',
      name: 'Sage',
      title: 'The Sage',
      description:
          'Inner peace is your superpower. Through mindfulness and reflection, you cultivate deep emotional intelligence.',
      icon: '🧘',
      color: Color(0xFFA9C9B8),
      statWeights: {'mind': 0.4, 'heart': 0.4, 'discipline': 0.2},
    ),
    Archetype(
      id: 'guardian',
      name: 'Guardian',
      title: 'The Guardian',
      description:
          'You show up for others with unwavering consistency. Your strength comes from the bonds you protect.',
      icon: '🛡️',
      color: Color(0xFFA9BCD4),
      statWeights: {'heart': 0.4, 'discipline': 0.3, 'body': 0.3},
    ),
    Archetype(
      id: 'titan',
      name: 'Titan',
      title: 'The Titan',
      description:
          'A rare balance of all virtues. You pursue excellence across every dimension of life.',
      icon: '👑',
      color: Color(0xFFC4A882),
      statWeights: {
        'body': 0.17,
        'mind': 0.17,
        'knowledge': 0.17,
        'heart': 0.17,
        'discipline': 0.16,
        'craft': 0.16,
      },
    ),
  ];

  static Archetype calculate(Map<String, int> stats) {
    if (stats.isEmpty) return all.last;

    double bestScore = -1;
    Archetype best = all.last;

    for (final archetype in all) {
      double score = 0;
      for (final entry in archetype.statWeights.entries) {
        score += (stats[entry.key] ?? 0) * entry.value;
      }
      if (score > bestScore) {
        bestScore = score;
        best = archetype;
      }
    }

    // Titan requires balanced stats (no stat more than 2x another)
    if (stats.length >= 4) {
      final values = stats.values.where((v) => v > 0).toList();
      if (values.isNotEmpty) {
        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);
        if (min > 0 && max / min <= 2.0 && values.length >= 5) {
          return all.firstWhere((a) => a.id == 'titan');
        }
      }
    }

    return best;
  }
}
