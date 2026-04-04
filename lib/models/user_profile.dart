import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String? avatarUrl;
  final bool onboardingComplete;
  final String commitmentLevel; // '15', '30', '45', '60' minutes
  final String energyPreference; // 'gentle', 'balanced', 'intense'
  final List<String> problems;
  final List<String> goals;
  final String? northStarVision;
  final int currentProgrammeNumber;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    this.avatarUrl,
    this.onboardingComplete = false,
    this.commitmentLevel = '30',
    this.energyPreference = 'balanced',
    this.problems = const [],
    this.goals = const [],
    this.northStarVision,
    this.currentProgrammeNumber = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'avatarUrl': avatarUrl,
        'onboardingComplete': onboardingComplete,
        'commitmentLevel': commitmentLevel,
        'energyPreference': energyPreference,
        'problems': problems,
        'goals': goals,
        'northStarVision': northStarVision,
        'currentProgrammeNumber': currentProgrammeNumber,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        uid: map['uid'] ?? '',
        name: map['name'] ?? '',
        avatarUrl: map['avatarUrl'],
        onboardingComplete: map['onboardingComplete'] ?? false,
        commitmentLevel: map['commitmentLevel'] ?? '30',
        energyPreference: map['energyPreference'] ?? 'balanced',
        problems: List<String>.from(map['problems'] ?? []),
        goals: List<String>.from(map['goals'] ?? []),
        northStarVision: map['northStarVision'],
        currentProgrammeNumber: map['currentProgrammeNumber'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  UserProfile copyWith({
    String? name,
    String? avatarUrl,
    bool? onboardingComplete,
    String? commitmentLevel,
    String? energyPreference,
    List<String>? problems,
    List<String>? goals,
    String? northStarVision,
    int? currentProgrammeNumber,
  }) =>
      UserProfile(
        uid: uid,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        commitmentLevel: commitmentLevel ?? this.commitmentLevel,
        energyPreference: energyPreference ?? this.energyPreference,
        problems: problems ?? this.problems,
        goals: goals ?? this.goals,
        northStarVision: northStarVision ?? this.northStarVision,
        currentProgrammeNumber:
            currentProgrammeNumber ?? this.currentProgrammeNumber,
        createdAt: createdAt,
      );
}
