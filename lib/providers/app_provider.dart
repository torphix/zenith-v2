import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/adhoc_task.dart';
import '../models/archetype.dart';
import '../models/assessment.dart';
import '../models/coach_message.dart';
import '../models/completion.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../models/photo_entry.dart';
import '../models/programme.dart';
import '../models/quest.dart';
import '../models/stat_snapshot.dart';
import '../models/sub_skill.dart';
import '../models/user_profile.dart';
import '../models/voice_note.dart';
import '../models/wrap_data.dart';
import '../services/ai_service.dart';
import '../services/firestore_service.dart';
import '../services/logger.dart';
import '../services/storage_service.dart';

const _uuid = Uuid();
const _tag = 'AppProvider';

class AppProvider extends ChangeNotifier {
  final _firestore = FirestoreService();
  final _ai = AIService();
  final _storage = StorageService();

  // ── State ──
  UserProfile? _profile;
  Assessment? _assessment;
  Programme? _programme;
  List<Quest> _quests = [];
  List<Habit> _habits = [];
  List<Completion> _todayCompletions = [];
  StatSnapshot _stats = StatSnapshot();
  Archetype _archetype = Archetype.all.first;
  List<CoachMessage> _chatMessages = [];
  List<AdhocTask> _todayAdhocTasks = [];
  List<JournalEntry> _todayJournalEntries = [];
  List<SubSkill> _subSkills = [];
  bool _isLoading = false;
  bool _isProcessingVoiceNote = false;
  String? _error;

  // ── Getters ──
  UserProfile? get profile => _profile;
  Assessment? get assessment => _assessment;
  Programme? get programme => _programme;
  List<Quest> get quests => _quests;
  List<Habit> get habits => _habits;
  List<Completion> get todayCompletions => _todayCompletions;
  StatSnapshot get stats => _stats;
  Archetype get archetype => _archetype;
  List<CoachMessage> get chatMessages => _chatMessages;
  List<AdhocTask> get todayAdhocTasks => _todayAdhocTasks;
  List<JournalEntry> get todayJournalEntries => _todayJournalEntries;
  List<SubSkill> get subSkills => _subSkills;
  bool get isLoading => _isLoading;
  bool get isProcessingVoiceNote => _isProcessingVoiceNote;
  String? get error => _error;

  bool get hasCompletedOnboarding => _profile?.onboardingComplete ?? false;

  /// Consume the current error (returns it and clears state).
  String? consumeError() {
    final err = _error;
    _error = null;
    return err;
  }

  double get todayCompletionRate {
    if (_habits.isEmpty) return 0;
    final completed =
        _todayCompletions.where((c) => c.completed).length;
    return completed / _habits.length;
  }

  int get todayXP =>
      _todayCompletions.fold(0, (sum, c) => sum + c.xpEarned);

  /// Total minutes invested today across habits and ad-hoc tasks.
  int get todayMinutesInvested {
    final habitMins = _todayCompletions
        .where((c) => c.completed && c.value != null)
        .fold(0, (sum, c) => sum + c.value!);
    final adhocMins = _todayAdhocTasks
        .where((t) => t.completed && t.minutesSpent != null)
        .fold(0, (sum, t) => sum + t.minutesSpent!);
    return habitMins + adhocMins;
  }

  /// Minutes grouped by sub-skill domain.
  Map<String, int> get todayTimeByCategory {
    final map = <String, int>{};
    for (final c in _todayCompletions.where((c) => c.completed && c.value != null)) {
      final habit = _habits.where((h) => h.id == c.habitId).firstOrNull;
      if (habit != null) {
        final skill = _subSkills.where((s) => s.id == habit.subSkillId).firstOrNull;
        final domain = skill?.domain ?? 'discipline';
        map[domain] = (map[domain] ?? 0) + c.value!;
      }
    }
    for (final t in _todayAdhocTasks.where((t) => t.completed && t.minutesSpent != null)) {
      if (t.subSkillId != null) {
        final skill = _subSkills.where((s) => s.id == t.subSkillId).firstOrNull;
        final domain = skill?.domain ?? 'discipline';
        map[domain] = (map[domain] ?? 0) + t.minutesSpent!;
      }
    }
    return map;
  }

  /// Per-habit minutes invested today (habitId → minutes).
  Map<String, int> get todayMinutesByHabit {
    final map = <String, int>{};
    for (final c in _todayCompletions.where((c) => c.completed && c.value != null)) {
      map[c.habitId] = c.value!;
    }
    return map;
  }

  /// XP gained today per sub-skill ID.
  Map<String, int> get todayStatsGained {
    final map = <String, int>{};
    for (final c in _todayCompletions.where((c) => c.completed)) {
      final habit = _habits.where((h) => h.id == c.habitId).firstOrNull;
      if (habit != null) {
        map[habit.subSkillId] =
            (map[habit.subSkillId] ?? 0) + habit.baseXP;
      }
    }
    return map;
  }

  // ── Init ──

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _firestore.getProfile();
      if (_profile != null && _profile!.onboardingComplete) {
        await _loadActiveData();
      }
    } catch (e, st) {
      Log.error(_tag, 'Failed to initialise app', e, st);
      _error = Log.friendlyMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadActiveData() async {
    _programme = await _firestore.getActiveProgramme();
    _stats = await _firestore.getStats();
    _assessment = await _firestore.getLatestAssessment();
    _subSkills = await _firestore.getSubSkills();

    // Migrate legacy stats if needed
    if (_stats.needsMigration) {
      final (migrated, newSkills) = _stats.migrate();
      _stats = migrated;
      // Only create sub-skills that don't already exist
      final existing = _subSkills.map((s) => s.id).toSet();
      final toCreate = newSkills.where((s) => !existing.contains(s.id)).toList();
      if (toCreate.isNotEmpty) {
        await _firestore.saveSubSkills(toCreate);
        _subSkills = [..._subSkills, ...toCreate];
      }
      await _firestore.saveStats(_stats);
    }

    // Calculate archetype from domain totals
    final domainTotals = _stats.domainTotals(_subSkills);
    _archetype = Archetype.calculate(domainTotals);

    if (_programme != null) {
      _habits = await _firestore.getHabitsForProgramme(_programme!.id);
      _quests = await _firestore.getQuestsForProgramme(_programme!.id);
      _todayCompletions =
          await _firestore.getCompletionsForDate(DateTime.now());
    }
    _todayAdhocTasks = await _firestore.getAdhocTasksForDate(DateTime.now());
    _todayJournalEntries =
        await _firestore.getJournalEntriesForDate(DateTime.now());
  }

  // ── Journal ──

  bool hasJournaledToday(String type) =>
      _todayJournalEntries.any((e) => e.type == type);

  Future<void> saveJournalEntry({
    required String type,
    required String prompt,
    required String response,
  }) async {
    final entry = JournalEntry(
      id: _uuid.v4(),
      type: type,
      prompt: prompt,
      response: response,
    );
    await _firestore.saveJournalEntry(entry);
    _todayJournalEntries.add(entry);
    notifyListeners();
  }

  // ── Past Programmes ──

  Future<List<Programme>> getPastProgrammes() async {
    final all = await _firestore.getAllProgrammes();
    return all.where((p) => !p.isActive).toList();
  }

  Future<List<Habit>> getHabitsForProgramme(String programmeId) =>
      _firestore.getHabitsForProgramme(programmeId);

  Future<List<Quest>> getQuestsForProgramme(String programmeId) =>
      _firestore.getQuestsForProgramme(programmeId);

  // ── Onboarding ──

  Future<void> saveOnboardingProfile({
    required String name,
    required List<String> problems,
    required List<String> goals,
    required String commitmentLevel,
    required String energyPreference,
    String? northStarVision,
    required Map<String, int> assessmentScores,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = _firestore.uid;
      _profile = UserProfile(
        uid: uid,
        name: name,
        problems: problems,
        goals: goals,
        commitmentLevel: commitmentLevel,
        energyPreference: energyPreference,
        northStarVision: northStarVision,
        onboardingComplete: true,
        currentProgrammeNumber: 1,
      );
      await _firestore.saveProfile(_profile!);

      // Save assessment
      _assessment = Assessment(
        id: _uuid.v4(),
        scores: assessmentScores,
      );
      await _firestore.saveAssessment(_assessment!);

      // Generate programme
      await _generateProgramme(
        assessmentScores: assessmentScores,
        northStarVision: northStarVision,
        problems: problems,
        goals: goals,
        commitmentLevel: commitmentLevel,
        energyPreference: energyPreference,
      );

      // Calculate archetype from sub-skill domain distribution
      {
        final dc = <String, int>{};
        for (final s in _subSkills) {
          dc[s.domain] = (dc[s.domain] ?? 0) + 1;
        }
        if (dc.isNotEmpty) _archetype = Archetype.calculate(dc);
      }

      // Init stats
      _stats = StatSnapshot(archetypeId: _archetype.id);
      await _firestore.saveStats(_stats);

      // Generate starter tasks from north star vision
      if (northStarVision != null && northStarVision.isNotEmpty) {
        try {
          final taskMaps = await _ai.generateStarterTasks(
            northStarVision: northStarVision,
            goals: goals,
            problems: problems,
          );
          for (final t in taskMaps) {
            // Create or find sub-skill
            final skillName = t['subSkillName'] as String? ?? 'General';
            final skillId = skillName.toLowerCase().replaceAll(' ', '_');
            final skillDomain = t['subSkillDomain'] as String? ?? 'discipline';
            final skillIcon = t['subSkillIcon'] as String? ?? '⭐';

            if (!_subSkills.any((s) => s.id == skillId)) {
              final newSkill = SubSkill(
                id: skillId,
                name: skillName,
                icon: skillIcon,
                domain: skillDomain,
              );
              await _firestore.saveSubSkill(newSkill);
              _subSkills.add(newSkill);
            }

            final task = AdhocTask(
              id: _uuid.v4(),
              title: t['title'] as String? ?? '',
              subSkillId: skillId,
              xp: (t['xp'] as num?)?.toInt() ?? 10,
            );
            await _firestore.saveAdhocTask(task);
            _todayAdhocTasks.add(task);
          }
        } catch (e, st) {
          // Non-critical — don't fail onboarding for this
          Log.error(_tag, 'Failed to generate starter tasks', e, st);
        }
      }
    } catch (e, st) {
      Log.error(_tag, 'Failed to save onboarding profile', e, st);
      _error = Log.friendlyMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Complete onboarding from an AI conversation transcript.
  Future<void> completeConversationalOnboarding({
    required String name,
    required List<String> conversationHistory,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = _firestore.uid;

      // Extract structured profile from conversation
      final extracted = await _ai.extractOnboardingProfile(
        userName: name,
        conversationHistory: conversationHistory,
      );

      final problems = List<String>.from(extracted['problems'] ?? []);
      final goals = List<String>.from(extracted['goals'] ?? []);
      final northStarVision = extracted['northStarVision'] as String?;
      final energyPreference =
          extracted['energyPreference'] as String? ?? 'balanced';
      final commitmentLevel =
          extracted['commitmentLevel'] as String? ?? '30';
      final scoresRaw =
          extracted['assessmentScores'] as Map<String, dynamic>? ?? {};
      final assessmentScores = scoresRaw.map(
        (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 5),
      );

      _profile = UserProfile(
        uid: uid,
        name: name,
        problems: problems,
        goals: goals,
        commitmentLevel: commitmentLevel,
        energyPreference: energyPreference,
        northStarVision: northStarVision,
        onboardingComplete: true,
        currentProgrammeNumber: 1,
      );
      await _firestore.saveProfile(_profile!);

      // Save assessment
      _assessment = Assessment(
        id: _uuid.v4(),
        scores: assessmentScores,
      );
      await _firestore.saveAssessment(_assessment!);

      // Generate programme from conversation
      final result = await _ai.generateProgrammeFromConversation(
        userName: name,
        conversationHistory: conversationHistory,
        extractedProfile: extracted,
      );

      final programmeData = result['programme'] as Map<String, dynamic>;
      final programmeId = _uuid.v4();

      _programme = Programme(
        id: programmeId,
        name: programmeData['name'] ?? 'Your Programme',
        theme: programmeData['theme'] ?? '',
        description: programmeData['description'] ?? '',
        focusPillars:
            List<String>.from(programmeData['focusPillars'] ?? []),
        coachingNote: programmeData['coachingNote'] ?? '',
        programmeNumber: 1,
      );
      await _firestore.saveProgramme(_programme!);

      // Save quests
      final questsData = programmeData['quests'] as List? ?? [];
      _quests = [];
      for (final q in questsData) {
        final qMap = q as Map<String, dynamic>;
        // Create or find sub-skill for quest
        final qSkillName = qMap['subSkillName'] as String? ?? 'General';
        final qSkillId = qSkillName.toLowerCase().replaceAll(' ', '_');
        final qSkillDomain = qMap['subSkillDomain'] as String? ?? 'discipline';
        final qSkillIcon = qMap['subSkillIcon'] as String? ?? '⭐';

        if (!_subSkills.any((s) => s.id == qSkillId)) {
          final newSkill = SubSkill(
            id: qSkillId,
            name: qSkillName,
            icon: qSkillIcon,
            domain: qSkillDomain,
          );
          await _firestore.saveSubSkill(newSkill);
          _subSkills.add(newSkill);
        }

        final quest = Quest(
          id: _uuid.v4(),
          programmeId: programmeId,
          title: qMap['title'] ?? '',
          description: qMap['description'] ?? '',
          subSkillId: qSkillId,
          phases: (qMap['phases'] as List?)
                  ?.map((p) =>
                      QuestPhase.fromMap(p as Map<String, dynamic>))
                  .toList() ??
              [],
        );
        await _firestore.saveQuest(quest);
        _quests.add(quest);
      }

      // Save habits
      final habitsData = programmeData['habits'] as List? ?? [];
      _habits = [];
      for (final h in habitsData) {
        final hMap = h as Map<String, dynamic>;
        // Create or find sub-skill for habit
        final hSkillName = hMap['subSkillName'] as String? ?? 'General';
        final hSkillId = hSkillName.toLowerCase().replaceAll(' ', '_');
        final hSkillDomain = hMap['subSkillDomain'] as String? ?? 'discipline';
        final hSkillIcon = hMap['subSkillIcon'] as String? ?? '⭐';

        if (!_subSkills.any((s) => s.id == hSkillId)) {
          final newSkill = SubSkill(
            id: hSkillId,
            name: hSkillName,
            icon: hSkillIcon,
            domain: hSkillDomain,
          );
          await _firestore.saveSubSkill(newSkill);
          _subSkills.add(newSkill);
        }

        final habit = Habit(
          id: _uuid.v4(),
          programmeId: programmeId,
          name: hMap['name'] ?? '',
          type: HabitType.values.firstWhere(
            (t) => t.name == hMap['type'],
            orElse: () => HabitType.checkbox,
          ),
          subSkillId: hSkillId,
          baseXP: hMap['baseXP'] ?? 10,
          targetValue: hMap['targetValue'],
          unit: hMap['unit'],
        );
        await _firestore.saveHabit(habit);
        _habits.add(habit);
      }

      // Calculate archetype from sub-skill domain distribution
      {
        final dc = <String, int>{};
        for (final s in _subSkills) {
          dc[s.domain] = (dc[s.domain] ?? 0) + 1;
        }
        if (dc.isNotEmpty) _archetype = Archetype.calculate(dc);
      }

      // Init stats
      _stats = StatSnapshot(archetypeId: _archetype.id);
      await _firestore.saveStats(_stats);

      // Generate starter tasks
      if (northStarVision != null && northStarVision.isNotEmpty) {
        try {
          final taskMaps = await _ai.generateStarterTasks(
            northStarVision: northStarVision,
            goals: goals,
            problems: problems,
          );
          for (final t in taskMaps) {
            // Create or find sub-skill
            final skillName = t['subSkillName'] as String? ?? 'General';
            final skillId = skillName.toLowerCase().replaceAll(' ', '_');
            final skillDomain = t['subSkillDomain'] as String? ?? 'discipline';
            final skillIcon = t['subSkillIcon'] as String? ?? '⭐';

            if (!_subSkills.any((s) => s.id == skillId)) {
              final newSkill = SubSkill(
                id: skillId,
                name: skillName,
                icon: skillIcon,
                domain: skillDomain,
              );
              await _firestore.saveSubSkill(newSkill);
              _subSkills.add(newSkill);
            }

            final task = AdhocTask(
              id: _uuid.v4(),
              title: t['title'] as String? ?? '',
              subSkillId: skillId,
              xp: (t['xp'] as num?)?.toInt() ?? 10,
            );
            await _firestore.saveAdhocTask(task);
            _todayAdhocTasks.add(task);
          }
        } catch (e, st) {
          Log.error(_tag, 'Failed to generate starter tasks', e, st);
        }
      }
    } catch (e, st) {
      Log.error(_tag, 'Failed to complete onboarding', e, st);
      _error = Log.friendlyMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Complete onboarding using structured questionnaire data + AI conversation.
  Future<void> completeOnboardingWithData({
    required String name,
    List<String> selectedGoals = const [],
    List<String> painPoints = const [],
    List<String> preferences = const [],
    required String commitmentLevel,
    required String energyPreference,
    required List<String> conversationHistory,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uid = _firestore.uid;

      // Build enriched conversation context for extraction
      final enrichedHistory = <String>[
        'system_context: Questionnaire answers — Goals: ${selectedGoals.isNotEmpty ? selectedGoals.join(", ") : "not specified"}, '
            'Pain points: ${painPoints.join(", ")}, '
            'Preferences: ${preferences.join(", ")}, '
            'Commitment: $commitmentLevel min/day, '
            'Energy: $energyPreference',
        ...conversationHistory,
      ];

      // Extract structured profile from conversation + questionnaire
      final extracted = await _ai.extractOnboardingProfile(
        userName: name,
        conversationHistory: enrichedHistory,
      );

      // Merge: prefer questionnaire answers for structured fields,
      // conversation-extracted data for open-ended fields
      final problems = painPoints.isNotEmpty
          ? painPoints
          : List<String>.from(extracted['problems'] ?? []);
      final goals = <String>[
        ...selectedGoals,
        ...List<String>.from(extracted['goals'] ?? []),
      ];
      final northStarVision = extracted['northStarVision'] as String?;

      final scoresRaw =
          extracted['assessmentScores'] as Map<String, dynamic>? ?? {};
      final assessmentScores = scoresRaw.map(
        (k, v) => MapEntry(k, (v as num?)?.toInt() ?? 5),
      );

      _profile = UserProfile(
        uid: uid,
        name: name,
        problems: problems,
        goals: goals,
        commitmentLevel: commitmentLevel,
        energyPreference: energyPreference,
        northStarVision: northStarVision,
        onboardingComplete: true,
        currentProgrammeNumber: 1,
      );
      await _firestore.saveProfile(_profile!);

      _assessment = Assessment(id: _uuid.v4(), scores: assessmentScores);
      await _firestore.saveAssessment(_assessment!);

      // Generate programme using both questionnaire + conversation data
      final enrichedProfile = <String, dynamic>{
        ...extracted,
        'selectedGoals': selectedGoals,
        'painPoints': painPoints,
        'preferences': preferences,
        'commitmentLevel': commitmentLevel,
        'energyPreference': energyPreference,
      };

      final result = await _ai.generateProgrammeFromConversation(
        userName: name,
        conversationHistory: enrichedHistory,
        extractedProfile: enrichedProfile,
      );

      final programmeData = result['programme'] as Map<String, dynamic>;
      final programmeId = _uuid.v4();

      _programme = Programme(
        id: programmeId,
        name: programmeData['name'] ?? 'Your Programme',
        theme: programmeData['theme'] ?? '',
        description: programmeData['description'] ?? '',
        focusPillars:
            List<String>.from(programmeData['focusPillars'] ?? []),
        coachingNote: programmeData['coachingNote'] ?? '',
        programmeNumber: 1,
      );
      await _firestore.saveProgramme(_programme!);

      // Save quests
      final questsData = programmeData['quests'] as List? ?? [];
      _quests = [];
      for (final q in questsData) {
        final qMap = q as Map<String, dynamic>;
        // Create or find sub-skill for quest
        final qSkillName = qMap['subSkillName'] as String? ?? 'General';
        final qSkillId = qSkillName.toLowerCase().replaceAll(' ', '_');
        final qSkillDomain = qMap['subSkillDomain'] as String? ?? 'discipline';
        final qSkillIcon = qMap['subSkillIcon'] as String? ?? '⭐';

        if (!_subSkills.any((s) => s.id == qSkillId)) {
          final newSkill = SubSkill(
            id: qSkillId,
            name: qSkillName,
            icon: qSkillIcon,
            domain: qSkillDomain,
          );
          await _firestore.saveSubSkill(newSkill);
          _subSkills.add(newSkill);
        }

        final quest = Quest(
          id: _uuid.v4(),
          programmeId: programmeId,
          title: qMap['title'] ?? '',
          description: qMap['description'] ?? '',
          subSkillId: qSkillId,
          phases: (qMap['phases'] as List?)
                  ?.map((p) =>
                      QuestPhase.fromMap(p as Map<String, dynamic>))
                  .toList() ??
              [],
        );
        await _firestore.saveQuest(quest);
        _quests.add(quest);
      }

      // Save habits
      final habitsData = programmeData['habits'] as List? ?? [];
      _habits = [];
      for (final h in habitsData) {
        final hMap = h as Map<String, dynamic>;
        // Create or find sub-skill for habit
        final hSkillName = hMap['subSkillName'] as String? ?? 'General';
        final hSkillId = hSkillName.toLowerCase().replaceAll(' ', '_');
        final hSkillDomain = hMap['subSkillDomain'] as String? ?? 'discipline';
        final hSkillIcon = hMap['subSkillIcon'] as String? ?? '⭐';

        if (!_subSkills.any((s) => s.id == hSkillId)) {
          final newSkill = SubSkill(
            id: hSkillId,
            name: hSkillName,
            icon: hSkillIcon,
            domain: hSkillDomain,
          );
          await _firestore.saveSubSkill(newSkill);
          _subSkills.add(newSkill);
        }

        final habit = Habit(
          id: _uuid.v4(),
          programmeId: programmeId,
          name: hMap['name'] ?? '',
          type: HabitType.values.firstWhere(
            (t) => t.name == hMap['type'],
            orElse: () => HabitType.checkbox,
          ),
          subSkillId: hSkillId,
          baseXP: hMap['baseXP'] ?? 10,
          targetValue: hMap['targetValue'],
          unit: hMap['unit'],
        );
        await _firestore.saveHabit(habit);
        _habits.add(habit);
      }

      // Calculate archetype from sub-skill domain distribution
      {
        final dc = <String, int>{};
        for (final s in _subSkills) {
          dc[s.domain] = (dc[s.domain] ?? 0) + 1;
        }
        if (dc.isNotEmpty) _archetype = Archetype.calculate(dc);
      }

      // Init stats
      _stats = StatSnapshot(archetypeId: _archetype.id);
      await _firestore.saveStats(_stats);

      // Generate starter tasks
      if (northStarVision != null && northStarVision.isNotEmpty) {
        try {
          final taskMaps = await _ai.generateStarterTasks(
            northStarVision: northStarVision,
            goals: goals,
            problems: problems,
          );
          for (final t in taskMaps) {
            // Create or find sub-skill
            final skillName = t['subSkillName'] as String? ?? 'General';
            final skillId = skillName.toLowerCase().replaceAll(' ', '_');
            final skillDomain = t['subSkillDomain'] as String? ?? 'discipline';
            final skillIcon = t['subSkillIcon'] as String? ?? '⭐';

            if (!_subSkills.any((s) => s.id == skillId)) {
              final newSkill = SubSkill(
                id: skillId,
                name: skillName,
                icon: skillIcon,
                domain: skillDomain,
              );
              await _firestore.saveSubSkill(newSkill);
              _subSkills.add(newSkill);
            }

            final task = AdhocTask(
              id: _uuid.v4(),
              title: t['title'] as String? ?? '',
              subSkillId: skillId,
              xp: (t['xp'] as num?)?.toInt() ?? 10,
            );
            await _firestore.saveAdhocTask(task);
            _todayAdhocTasks.add(task);
          }
        } catch (e, st) {
          Log.error(_tag, 'Failed to generate starter tasks', e, st);
        }
      }
    } catch (e, st) {
      Log.error(_tag, 'Failed to complete onboarding', e, st);
      _error = Log.friendlyMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Resets onboarding so the user can redo it.
  Future<void> resetOnboarding() async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedProfile = _profile!.copyWith(onboardingComplete: false);
      await _firestore.saveProfile(updatedProfile);
      _profile = updatedProfile;

      // Clear local state
      _programme = null;
      _quests = [];
      _habits = [];
      _todayCompletions = [];
      _todayAdhocTasks = [];
      _stats = StatSnapshot();
      _archetype = Archetype.all.first;
      _chatMessages = [];
      _assessment = null;
    } catch (e, st) {
      Log.error(_tag, 'Failed to reset onboarding', e, st);
      _error = Log.friendlyMessage(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _generateProgramme({
    required Map<String, int> assessmentScores,
    String? northStarVision,
    List<String> problems = const [],
    List<String> goals = const [],
    String commitmentLevel = '30',
    String energyPreference = 'balanced',
  }) async {
    final result = await _ai.generateProgramme(
      assessmentScores: assessmentScores,
      northStarVision: northStarVision,
      problems: problems,
      goals: goals,
      commitmentLevel: commitmentLevel,
      energyPreference: energyPreference,
      programmeNumber: _profile?.currentProgrammeNumber ?? 1,
    );

    final programmeData = result['programme'] as Map<String, dynamic>;
    final programmeId = _uuid.v4();

    _programme = Programme(
      id: programmeId,
      name: programmeData['name'] ?? 'Your Programme',
      theme: programmeData['theme'] ?? '',
      description: programmeData['description'] ?? '',
      focusPillars:
          List<String>.from(programmeData['focusPillars'] ?? []),
      coachingNote: programmeData['coachingNote'] ?? '',
      programmeNumber: _profile?.currentProgrammeNumber ?? 1,
    );
    await _firestore.saveProgramme(_programme!);

    // Save quests
    final questsData = programmeData['quests'] as List? ?? [];
    _quests = [];
    for (final q in questsData) {
      final qMap = q as Map<String, dynamic>;
      // Create or find sub-skill for quest
      final qSkillName = qMap['subSkillName'] as String? ?? 'General';
      final qSkillId = qSkillName.toLowerCase().replaceAll(' ', '_');
      final qSkillDomain = qMap['subSkillDomain'] as String? ?? 'discipline';
      final qSkillIcon = qMap['subSkillIcon'] as String? ?? '⭐';

      if (!_subSkills.any((s) => s.id == qSkillId)) {
        final newSkill = SubSkill(
          id: qSkillId,
          name: qSkillName,
          icon: qSkillIcon,
          domain: qSkillDomain,
        );
        await _firestore.saveSubSkill(newSkill);
        _subSkills.add(newSkill);
      }

      final quest = Quest(
        id: _uuid.v4(),
        programmeId: programmeId,
        title: qMap['title'] ?? '',
        description: qMap['description'] ?? '',
        subSkillId: qSkillId,
        phases: (qMap['phases'] as List?)
                ?.map((p) =>
                    QuestPhase.fromMap(p as Map<String, dynamic>))
                .toList() ??
            [],
      );
      await _firestore.saveQuest(quest);
      _quests.add(quest);
    }

    // Save habits
    final habitsData = programmeData['habits'] as List? ?? [];
    _habits = [];
    for (final h in habitsData) {
      final hMap = h as Map<String, dynamic>;
      // Create or find sub-skill for habit
      final hSkillName = hMap['subSkillName'] as String? ?? 'General';
      final hSkillId = hSkillName.toLowerCase().replaceAll(' ', '_');
      final hSkillDomain = hMap['subSkillDomain'] as String? ?? 'discipline';
      final hSkillIcon = hMap['subSkillIcon'] as String? ?? '⭐';

      if (!_subSkills.any((s) => s.id == hSkillId)) {
        final newSkill = SubSkill(
          id: hSkillId,
          name: hSkillName,
          icon: hSkillIcon,
          domain: hSkillDomain,
        );
        await _firestore.saveSubSkill(newSkill);
        _subSkills.add(newSkill);
      }

      final habit = Habit(
        id: _uuid.v4(),
        programmeId: programmeId,
        name: hMap['name'] ?? '',
        type: HabitType.values.firstWhere(
          (t) => t.name == hMap['type'],
          orElse: () => HabitType.checkbox,
        ),
        subSkillId: hSkillId,
        baseXP: hMap['baseXP'] ?? 10,
        targetValue: hMap['targetValue'],
        unit: hMap['unit'],
      );
      await _firestore.saveHabit(habit);
      _habits.add(habit);
    }
  }

  // ── Habit Completion ──

  Future<void> toggleHabit(Habit habit, {int? value}) async {
    // Optimistic update
    final existing = _todayCompletions
        .where((c) => c.habitId == habit.id)
        .firstOrNull;

    Completion optimistic;
    if (existing != null) {
      optimistic = existing.copyWith(
        completed: !existing.completed,
        xpEarned: !existing.completed ? habit.baseXP : 0,
      );
      _todayCompletions = _todayCompletions
          .map((c) => c.id == optimistic.id ? optimistic : c)
          .toList();
    } else {
      optimistic = Completion(
        id: _uuid.v4(),
        habitId: habit.id,
        programmeId: _programme?.id ?? '',
        date: DateTime.now(),
        completed: true,
        value: value,
        xpEarned: habit.baseXP,
      );
      _todayCompletions.add(optimistic);
    }
    notifyListeners();

    // Persist in background
    try {
      await _firestore.saveCompletion(optimistic);
      await _updateStats();
    } catch (e, st) {
      // Rollback
      Log.error(_tag, 'Failed to toggle habit', e, st);
      if (existing != null) {
        _todayCompletions = _todayCompletions
            .map((c) => c.id == existing.id ? existing : c)
            .toList();
      } else {
        _todayCompletions.removeWhere((c) => c.id == optimistic.id);
      }
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }

  /// Mark a habit complete with a specific duration in minutes.
  Future<void> completeHabitWithDuration(Habit habit, int minutes) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(minutes: minutes));
    final existing = _todayCompletions
        .where((c) => c.habitId == habit.id)
        .firstOrNull;

    Completion optimistic;
    if (existing != null) {
      optimistic = existing.copyWith(
        completed: true,
        value: minutes,
        startTime: start,
        endTime: now,
        xpEarned: habit.baseXP,
      );
      _todayCompletions = _todayCompletions
          .map((c) => c.id == optimistic.id ? optimistic : c)
          .toList();
    } else {
      optimistic = Completion(
        id: _uuid.v4(),
        habitId: habit.id,
        programmeId: _programme?.id ?? '',
        date: now,
        completed: true,
        value: minutes,
        startTime: start,
        endTime: now,
        xpEarned: habit.baseXP,
      );
      _todayCompletions.add(optimistic);
    }
    notifyListeners();

    try {
      await _firestore.saveCompletion(optimistic);
      await _updateStats();
    } catch (e, st) {
      Log.error(_tag, 'Failed to complete habit with duration', e, st);
      if (existing != null) {
        _todayCompletions = _todayCompletions
            .map((c) => c.id == existing.id ? existing : c)
            .toList();
      } else {
        _todayCompletions.removeWhere((c) => c.id == optimistic.id);
      }
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }

  /// Update the start/end time of a habit completion.
  Future<void> updateCompletionTime(
    String habitId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final existing = _todayCompletions
        .where((c) => c.habitId == habitId && c.completed)
        .firstOrNull;
    if (existing == null) return;

    final minutes = endTime.difference(startTime).inMinutes.clamp(1, 1440);
    final updated = existing.copyWith(
      startTime: startTime,
      endTime: endTime,
      value: minutes,
    );
    _todayCompletions = _todayCompletions
        .map((c) => c.id == updated.id ? updated : c)
        .toList();
    notifyListeners();

    try {
      await _firestore.saveCompletion(updated);
    } catch (e, st) {
      Log.error(_tag, 'Failed to update completion time', e, st);
      _todayCompletions = _todayCompletions
          .map((c) => c.id == existing.id ? existing : c)
          .toList();
      _error = Log.friendlyMessage(e);
      notifyListeners();
    }
  }

  /// Mark an ad-hoc task complete with duration.
  Future<void> completeAdhocTaskWithDuration(AdhocTask task, int minutes) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(minutes: minutes));
    final updated = task.copyWith(
      completed: true,
      minutesSpent: minutes,
      startTime: start,
      endTime: now,
    );
    _todayAdhocTasks = _todayAdhocTasks
        .map((t) => t.id == updated.id ? updated : t)
        .toList();
    notifyListeners();

    try {
      await _firestore.saveAdhocTask(updated);
    } catch (e, st) {
      Log.error(_tag, 'Failed to complete task with duration', e, st);
      _todayAdhocTasks = _todayAdhocTasks
          .map((t) => t.id == task.id ? task : t)
          .toList();
      _error = Log.friendlyMessage(e);
      notifyListeners();
    }
  }

  /// Update the start/end time of an ad-hoc task.
  Future<void> updateAdhocTaskTime(
    AdhocTask task,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final minutes = endTime.difference(startTime).inMinutes.clamp(1, 1440);
    final updated = task.copyWith(
      startTime: startTime,
      endTime: endTime,
      minutesSpent: minutes,
    );
    _todayAdhocTasks = _todayAdhocTasks
        .map((t) => t.id == updated.id ? updated : t)
        .toList();
    notifyListeners();

    try {
      await _firestore.saveAdhocTask(updated);
    } catch (e, st) {
      Log.error(_tag, 'Failed to update task time', e, st);
      _todayAdhocTasks = _todayAdhocTasks
          .map((t) => t.id == task.id ? task : t)
          .toList();
      _error = Log.friendlyMessage(e);
      notifyListeners();
    }
  }

  /// Save a photo or video locally for a habit completion.
  /// [mediaFile] is the captured/picked file.
  /// [mediaType] is 'photo' or 'video'.
  Future<void> addCompletionMedia(
    String habitId,
    File mediaFile,
    String mediaType,
  ) async {
    try {
      final existing = _todayCompletions
          .where((c) => c.habitId == habitId)
          .firstOrNull;
      if (existing == null) return;

      // Copy to app documents so it persists beyond cache
      final appDir = await _storage.getMediaDirectory();
      final ext = mediaType == 'video' ? 'mp4' : 'jpg';
      final dest = File('${appDir.path}/${existing.id}.$ext');
      await mediaFile.copy(dest.path);

      final updated = existing.copyWith(
        photoUrl: dest.path,
        mediaType: mediaType,
      );
      await _firestore.saveCompletion(updated);
      _todayCompletions = _todayCompletions
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
    } catch (e, st) {
      Log.error(_tag, 'Failed to save media', e, st);
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }

  /// Keep old name as alias for backwards compat within the codebase.
  Future<void> addCompletionPhoto(String habitId, File photo) =>
      addCompletionMedia(habitId, photo, 'photo');

  bool isHabitCompleted(String habitId) {
    return _todayCompletions.any(
      (c) => c.habitId == habitId && c.completed,
    );
  }

  Completion? getCompletionForHabit(String habitId) {
    return _todayCompletions
        .where((c) => c.habitId == habitId)
        .firstOrNull;
  }

  Future<List<Completion>> getCompletionsForDay(DateTime date) {
    return _firestore.getCompletionsForDate(date);
  }

  Future<void> _updateStats() async {
    final gained = todayStatsGained; // subSkillId → XP
    final newSubSkillXP = Map<String, int>.from(_stats.subSkillXP);
    for (final entry in gained.entries) {
      newSubSkillXP[entry.key] =
          (newSubSkillXP[entry.key] ?? 0) + entry.value;
    }

    // Also update the SubSkill objects in memory
    for (final entry in gained.entries) {
      final idx = _subSkills.indexWhere((s) => s.id == entry.key);
      if (idx >= 0) {
        _subSkills[idx].xp = newSubSkillXP[entry.key] ?? 0;
        await _firestore.saveSubSkill(_subSkills[idx]);
      }
    }

    final newTotalXP = _stats.totalXP + todayXP;
    var newLevel = _stats.level;
    while (newTotalXP >= StatSnapshot.xpForLevel(newLevel + 1)) {
      newLevel++;
    }

    // Update streak
    var newStreak = _stats.currentStreak;
    if (todayCompletionRate >= 0.8) {
      newStreak++;
    }

    final domainTotals = StatSnapshot(subSkillXP: newSubSkillXP)
        .domainTotals(_subSkills);
    _archetype = Archetype.calculate(domainTotals);

    _stats = _stats.copyWith(
      subSkillXP: newSubSkillXP,
      totalXP: newTotalXP,
      level: newLevel,
      currentStreak: newStreak,
      longestStreak:
          newStreak > _stats.longestStreak ? newStreak : _stats.longestStreak,
      archetypeId: _archetype.id,
    );
    await _firestore.saveStats(_stats);
  }

  // ── Daily Wrap ──

  Future<WrapData> generateDailyWrap() async {
    // Build photo entries with habit context
    final entries = <PhotoEntry>[];
    for (final c in _todayCompletions.where((c) => c.photoUrl != null)) {
      final habit = _habits.where((h) => h.id == c.habitId).firstOrNull;
      entries.add(PhotoEntry(
        localPath: c.photoUrl!,
        habitName: habit?.name ?? '',
        date: c.date,
      ));
    }

    // Compute previous stats (before today's gains)
    final gained = todayStatsGained;
    final prevStats = Map<String, int>.from(_stats.subSkillXP);
    for (final entry in gained.entries) {
      prevStats[entry.key] = (prevStats[entry.key] ?? 0) - entry.value;
    }

    final wrap = WrapData(
      id: 'daily_${DateTime.now().toIso8601String().substring(0, 10)}',
      type: 'daily',
      date: DateTime.now(),
      completionRate: todayCompletionRate,
      statsGained: todayStatsGained,
      skillsLeveledUp: todayStatsGained.keys.toList(),
      archetypeId: _archetype.id,
      totalXP: todayXP,
      habitsCompleted:
          _todayCompletions.where((c) => c.completed).length,
      habitsTotal: _habits.length,
      dayNumber: _programme?.currentDay ?? 1,
      photoUrls: _todayCompletions
          .where((c) => c.photoUrl != null)
          .map((c) => c.photoUrl!)
          .toList(),
      photoEntries: entries,
      previousStats: prevStats,
      highlights: _todayCompletions
          .where((c) => c.completed)
          .map((c) {
            final habit =
                _habits.where((h) => h.id == c.habitId).firstOrNull;
            return habit?.name ?? '';
          })
          .where((n) => n.isNotEmpty)
          .toList(),
    );

    await _firestore.saveWrap(wrap);
    return wrap;
  }

  Future<WrapData> generateWeeklyWrap() async {
    // Get last 7 days of wraps
    final dailyWraps = await _firestore.getWrapsOfType('daily', limit: 7);
    final totalXP = dailyWraps.fold(0, (sum, w) => sum + w.totalXP);
    final avgCompletion = dailyWraps.isEmpty
        ? 0.0
        : dailyWraps.fold(0.0, (sum, w) => sum + w.completionRate) /
            dailyWraps.length;

    final allStats = <String, int>{};
    for (final w in dailyWraps) {
      for (final entry in w.statsGained.entries) {
        allStats[entry.key] = (allStats[entry.key] ?? 0) + entry.value;
      }
    }

    // Aggregate photo entries from daily wraps
    final allPhotos = dailyWraps.expand((w) => w.photoEntries).toList();

    // Previous stats = current stats minus the week's aggregate gains
    final prevStats = Map<String, int>.from(_stats.subSkillXP);
    for (final entry in allStats.entries) {
      prevStats[entry.key] = (prevStats[entry.key] ?? 0) - entry.value;
    }

    final wrap = WrapData(
      id: 'weekly_${DateTime.now().toIso8601String().substring(0, 10)}',
      type: 'weekly',
      date: DateTime.now(),
      completionRate: avgCompletion,
      statsGained: allStats,
      skillsLeveledUp: allStats.keys.toList(),
      archetypeId: _archetype.id,
      totalXP: totalXP,
      habitsCompleted:
          dailyWraps.fold(0, (sum, w) => sum + w.habitsCompleted),
      habitsTotal: dailyWraps.fold(0, (sum, w) => sum + w.habitsTotal),
      dayNumber: _programme?.currentDay ?? 1,
      photoUrls:
          dailyWraps.expand((w) => w.photoUrls).toList(),
      photoEntries: allPhotos,
      previousStats: prevStats,
    );

    await _firestore.saveWrap(wrap);
    return wrap;
  }

  // ── Coach Chat ──

  /// Sends a voice message directly to the coach — audio goes straight
  /// to Gemini, no transcription step.
  Future<void> sendCoachVoiceMessage(File audioFile) async {
    _chatMessages.add(CoachMessage(role: 'user', content: '[Voice message]'));
    notifyListeners();

    try {
      final history =
          _chatMessages.map((m) => '${m.role}: ${m.content}').toList();

      final reply = await _ai.getCoachResponseFromAudio(
        audioFile: audioFile,
        profile: _profile?.toMap(),
        stats: _stats.toMap(),
        activeProgramme: _programme?.toMap(),
        conversationHistory: history,
      );

      _chatMessages.add(CoachMessage(role: 'coach', content: reply));
    } catch (e, st) {
      Log.error(_tag, 'Coach voice message failed', e, st);
      _chatMessages.add(CoachMessage(
        role: 'coach',
        content: 'Sorry, I had trouble connecting. Let\'s try again.',
      ));
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }

  Future<void> sendCoachMessage(String message) async {
    _chatMessages.add(CoachMessage(role: 'user', content: message));
    notifyListeners();

    try {
      final history =
          _chatMessages.map((m) => '${m.role}: ${m.content}').toList();

      final reply = await _ai.getCoachResponse(
        userMessage: message,
        profile: _profile?.toMap(),
        stats: _stats.toMap(),
        activeProgramme: _programme?.toMap(),
        conversationHistory: history,
      );

      _chatMessages.add(CoachMessage(role: 'coach', content: reply));
    } catch (e, st) {
      Log.error(_tag, 'Coach message failed', e, st);
      _chatMessages.add(CoachMessage(
        role: 'coach',
        content: 'Sorry, I had trouble connecting. Let\'s try again.',
      ));
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }

  /// Add a user message to chat history (for streaming coach flow).
  void addUserMessage(String content) {
    _chatMessages.add(CoachMessage(role: 'user', content: content));
    notifyListeners();
  }

  /// Add a coach message to chat history (for streaming coach flow).
  void addCoachMessage(String content) {
    _chatMessages.add(CoachMessage(role: 'coach', content: content));
    notifyListeners();
  }

  // ── Voice Notes & Ad-hoc Tasks ──

  /// Sends voice audio directly to Gemini to extract ad-hoc tasks,
  /// then uploads the audio for storage.
  Future<void> processVoiceNote(File audioFile) async {
    _isProcessingVoiceNote = true;
    notifyListeners();

    try {
      final noteId = _uuid.v4();

      // Send audio straight to Gemini — extract tasks directly
      final taskMaps = await _ai.processVoiceNoteAudio(
        audioFile: audioFile,
        profile: _profile?.toMap(),
        stats: _stats.toMap(),
        activeProgramme: _programme?.toMap(),
      );

      // Upload audio for storage
      final audioUrl = await _storage.uploadVoiceNote(
        noteId: noteId,
        file: audioFile,
      );

      // Save voice note record
      final voiceNote = VoiceNote(
        id: noteId,
        programmeId: _programme?.id,
        audioUrl: audioUrl,
      );
      await _firestore.saveVoiceNote(voiceNote);

      // Create ad-hoc tasks
      for (final t in taskMaps) {
        // Create or find sub-skill
        final skillName = t['subSkillName'] as String? ?? 'General';
        final skillId = skillName.toLowerCase().replaceAll(' ', '_');
        final skillDomain = t['subSkillDomain'] as String? ?? 'discipline';
        final skillIcon = t['subSkillIcon'] as String? ?? '⭐';

        if (!_subSkills.any((s) => s.id == skillId)) {
          final newSkill = SubSkill(
            id: skillId,
            name: skillName,
            icon: skillIcon,
            domain: skillDomain,
          );
          await _firestore.saveSubSkill(newSkill);
          _subSkills.add(newSkill);
        }

        final task = AdhocTask(
          id: _uuid.v4(),
          title: t['title'] as String? ?? '',
          voiceNoteId: noteId,
          completed: true, // user already did it
          subSkillId: skillId,
          xp: (t['xp'] as num?)?.toInt() ?? 5,
        );
        await _firestore.saveAdhocTask(task);
        _todayAdhocTasks.add(task);
      }
    } catch (e, st) {
      Log.error(_tag, 'Voice note processing failed', e, st);
      _error = Log.friendlyMessage(e);
    }

    _isProcessingVoiceNote = false;
    notifyListeners();
  }

  /// Add a custom daily habit to the current programme.
  /// The AI will assign a sub-skill on the next programme generation,
  /// but for now we create a default sub-skill from the habit name.
  Future<void> addCustomHabit({
    required String name,
    String type = 'checkbox',
    int? targetValue,
    String? unit,
  }) async {
    if (_programme == null) return;

    try {
      // Create a sub-skill from the habit name
      final skillId = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
      if (!_subSkills.any((s) => s.id == skillId)) {
        final newSkill = SubSkill(
          id: skillId,
          name: name,
          icon: '⭐',
          domain: 'discipline', // default, AI will refine later
        );
        await _firestore.saveSubSkill(newSkill);
        _subSkills.add(newSkill);
      }

      final habit = Habit(
        id: _uuid.v4(),
        programmeId: _programme!.id,
        name: name,
        type: HabitType.values.firstWhere(
          (t) => t.name == type,
          orElse: () => HabitType.checkbox,
        ),
        subSkillId: skillId,
        baseXP: 10,
        targetValue: targetValue,
        unit: unit,
      );
      await _firestore.saveHabit(habit);
      _habits.add(habit);
    } catch (e, st) {
      Log.error(_tag, 'Failed to add custom habit', e, st);
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }

  Future<void> addAdhocTask(String title) async {
    try {
      final task = AdhocTask(
        id: _uuid.v4(),
        title: title,
      );
      await _firestore.saveAdhocTask(task);
      _todayAdhocTasks.add(task);
    } catch (e, st) {
      Log.error(_tag, 'Failed to add task', e, st);
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }

  Future<void> toggleAdhocTask(AdhocTask task) async {
    // Optimistic update
    final updated = task.copyWith(completed: !task.completed);
    _todayAdhocTasks = _todayAdhocTasks
        .map((t) => t.id == updated.id ? updated : t)
        .toList();
    notifyListeners();

    try {
      await _firestore.saveAdhocTask(updated);
    } catch (e, st) {
      // Rollback
      Log.error(_tag, 'Failed to toggle task', e, st);
      _todayAdhocTasks = _todayAdhocTasks
          .map((t) => t.id == task.id ? task : t)
          .toList();
      _error = Log.friendlyMessage(e);
      notifyListeners();
    }
  }

  // ── Refresh ──

  Future<void> refreshTodayData() async {
    try {
      _todayAdhocTasks = await _firestore.getAdhocTasksForDate(DateTime.now());
      if (_programme != null) {
        _todayCompletions =
            await _firestore.getCompletionsForDate(DateTime.now());
        _stats = await _firestore.getStats();
        _subSkills = await _firestore.getSubSkills();
        final domainTotals = _stats.domainTotals(_subSkills);
        _archetype = Archetype.calculate(domainTotals);
      }
    } catch (e, st) {
      Log.error(_tag, 'Failed to refresh data', e, st);
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }
}
