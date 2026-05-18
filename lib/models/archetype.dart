import 'package:flutter/material.dart';

class Archetype {
  final String id;
  final String name;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final String imagePath; // asset path for tarot card art

  const Archetype({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.imagePath,
  });

  /// Example activities that embody this archetype (shown in gallery snackbar).
  String get activities {
    const map = {
      'olympian': 'Running, lifting, sports, physical training, body challenges',
      'maverick': 'Drawing, music, writing, design, creative projects',
      'sage': 'Meditation, journaling, mindfulness, spiritual practices',
      'monk': 'Routine building, discipline challenges, consistency streaks',
      'architect': 'Learning, reading, system design, knowledge work',
      'oracle': 'Deep thinking, pattern recognition, wisdom practices',
      'catalyst': 'Leadership, mentoring, community building, social impact',
      'strategist': 'Planning, goal-setting, analytical thinking, strategy',
      'polymath': 'Multi-domain learning, varied skill development',
      'muse':
          'Relationship building, emotional expression, inspiring others, creative connection',
    };
    return map[id] ?? '';
  }

  static const List<Archetype> all = [
    Archetype(
      id: 'olympian',
      name: 'Olympian',
      title: 'The Olympian',
      description:
          'Peak physical form. You train your body as a temple, pushing limits others won\'t touch.',
      icon: '🏛️',
      color: Color(0xFFC24B4B), // Crimson Rose
      imagePath: 'assets/archetypes/olympian.png',
    ),
    Archetype(
      id: 'maverick',
      name: 'Maverick',
      title: 'The Maverick',
      description:
          'You see the world differently. Through art and invention, you make the invisible visible.',
      icon: '⚡',
      color: Color(0xFFD4A24E),
      imagePath: 'assets/archetypes/maverick.png',
    ),
    Archetype(
      id: 'sage',
      name: 'Sage',
      title: 'The Sage',
      description:
          'Master of the inner world. Your stillness is your superpower, your awareness your blade.',
      icon: '🧘',
      color: Color(0xFF5BAD8A), // Jade Mist
      imagePath: 'assets/archetypes/sage.png',
    ),
    Archetype(
      id: 'monk',
      name: 'Monk',
      title: 'The Monk',
      description:
          'Unbreakable routine, unshakeable will. You show up when no one\'s watching.',
      icon: '🔥',
      color: Color(0xFF8B6B3D), // Burnt Bronze
      imagePath: 'assets/archetypes/monk.png',
    ),
    Archetype(
      id: 'architect',
      name: 'Architect',
      title: 'The Architect',
      description:
          'You build systems in your mind before they exist in the world. Knowledge is your foundation.',
      icon: '🏗️',
      color: Color(0xFF5B4EAE), // Royal Indigo
      imagePath: 'assets/archetypes/architecht.png',
    ),
    Archetype(
      id: 'oracle',
      name: 'Oracle',
      title: 'The Oracle',
      description:
          'Pattern-reader, truth-seeker. You connect dots others can\'t see.',
      icon: '🔮',
      color: Color(0xFF9B7EC8), // Celestial Violet
      imagePath: 'assets/archetypes/oracle.png',
    ),
    Archetype(
      id: 'catalyst',
      name: 'Catalyst',
      title: 'The Catalyst',
      description:
          'Your presence makes people level up. You spark transformation in everyone around you.',
      icon: '🔱',
      color: Color(0xFFD4836B), // Warm Coral
      imagePath: 'assets/archetypes/catalyst.png',
    ),
    Archetype(
      id: 'muse',
      name: 'Muse',
      title: 'The Muse',
      description:
          'You inspire through connection. Your emotional depth and creative spirit draw people in and leave them changed.',
      icon: '🎭',
      color: Color(0xFFD4577A), // Rose
      imagePath: 'assets/archetypes/muse.png',
    ),
    Archetype(
      id: 'strategist',
      name: 'Strategist',
      title: 'The Strategist',
      description:
          'You play the long game. Every move is calculated, every day a step in a plan only you can see.',
      icon: '♟️',
      color: Color(0xFF3D8B8B), // Deep Teal
      imagePath: 'assets/archetypes/strategist.png',
    ),
    Archetype(
      id: 'polymath',
      name: 'Polymath',
      title: 'The Polymath',
      description:
          'Renaissance mind. You refuse to be defined by one thing — you master them all.',
      icon: '🌟',
      color: Color(0xFF7BA3C4), // Arctic Silver
      imagePath: 'assets/archetypes/polymath.png',
    ),
  ];

  /// Calculate archetype from domain distribution.
  ///
  /// [domainTotals] maps domain id → total XP in that domain.
  /// [weeklyGrowthRate] is the ratio of this week's XP to last week's (optional,
  /// used for Phoenix detection). Pass null if not applicable.
  static Archetype calculate(Map<String, int> domainTotals) {
    final total =
        domainTotals.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) return all.firstWhere((a) => a.id == 'sage');

    // Calculate percentages per domain
    final pcts = <String, double>{};
    for (final entry in domainTotals.entries) {
      pcts[entry.key] = entry.value / total;
    }

    // Polymath: no domain >35% AND 3+ domains each >15%
    final meaningfulDomains = pcts.values.where((p) => p > 0.15).length;
    final maxPct = pcts.values.fold<double>(0, (a, b) => a > b ? a : b);
    if (maxPct <= 0.35 && meaningfulDomains >= 3) {
      return all.firstWhere((a) => a.id == 'polymath');
    }

    // Muse: social + creative both >25%
    if ((pcts['social'] ?? 0) > 0.25 && (pcts['creative'] ?? 0) > 0.25) {
      return all.firstWhere((a) => a.id == 'muse');
    }

    // Oracle: intellectual + spiritual both >25%
    if ((pcts['intellectual'] ?? 0) > 0.25 &&
        (pcts['spiritual'] ?? 0) > 0.25) {
      return all.firstWhere((a) => a.id == 'oracle');
    }

    // Strategist: intellectual + discipline both >25%
    if ((pcts['intellectual'] ?? 0) > 0.25 &&
        (pcts['discipline'] ?? 0) > 0.25) {
      return all.firstWhere((a) => a.id == 'strategist');
    }

    // Single-domain specialists: find the dominant domain
    String? dominant;
    double dominantPct = 0;
    for (final entry in pcts.entries) {
      if (entry.value > dominantPct) {
        dominantPct = entry.value;
        dominant = entry.key;
      }
    }

    // Map dominant domain to specialist archetype
    const domainToArchetype = {
      'physical': 'olympian',
      'creative': 'maverick',
      'spiritual': 'sage',
      'discipline': 'monk',
      'intellectual': 'architect',
      'social': 'catalyst',
    };

    final archetypeId = domainToArchetype[dominant] ?? 'sage';
    return all.firstWhere(
      (a) => a.id == archetypeId,
      orElse: () => all.firstWhere((a) => a.id == 'sage'),
    );
  }

  /// Calculate match scores for all archetypes.
  /// Returns a map of archetypeId → match percentage (0.0 to 1.0).
  static Map<String, double> matchScores(Map<String, int> domainTotals) {
    final total =
        domainTotals.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) {
      return {for (final a in all) a.id: 0.0};
    }

    final pcts = <String, double>{};
    for (final entry in domainTotals.entries) {
      pcts[entry.key] = entry.value / total;
    }

    return {
      // Specialists: score is the percentage of their domain
      'olympian': (pcts['physical'] ?? 0),
      'maverick': (pcts['creative'] ?? 0),
      'sage': (pcts['spiritual'] ?? 0),
      'monk': (pcts['discipline'] ?? 0),
      'architect': (pcts['intellectual'] ?? 0),
      'catalyst': (pcts['social'] ?? 0),
      // Muse: average of social + creative
      'muse': ((pcts['social'] ?? 0) + (pcts['creative'] ?? 0)) / 2,
      // Oracle: average of intellectual + spiritual
      'oracle':
          ((pcts['intellectual'] ?? 0) + (pcts['spiritual'] ?? 0)) / 2,
      // Polymath: inverse of max concentration (more balanced = higher)
      'polymath': 1.0 -
          pcts.values.fold<double>(0, (a, b) => a > b ? a : b),
      // Strategist: average of intellectual + discipline
      'strategist':
          ((pcts['intellectual'] ?? 0) + (pcts['discipline'] ?? 0)) / 2,
    };
  }
}
