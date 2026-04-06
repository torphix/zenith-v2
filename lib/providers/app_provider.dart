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
import '../models/programme.dart';
import '../models/quest.dart';
import '../models/stat_snapshot.dart';
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

  Map<String, int> get todayStatsGained {
    final map = <String, int>{};
    for (final c in _todayCompletions.where((c) => c.completed)) {
      final habit = _habits.where((h) => h.id == c.habitId).firstOrNull;
      if (habit != null) {
        map[habit.primaryStat] =
            (map[habit.primaryStat] ?? 0) + habit.baseXP;
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
    _archetype = Archetype.calculate(_stats.stats);

    if (_programme != null) {
      _habits = await _firestore.getHabitsForProgramme(_programme!.id);
      _quests = await _firestore.getQuestsForProgramme(_programme!.id);
      _todayCompletions =
          await _firestore.getCompletionsForDate(DateTime.now());
    }
    _todayAdhocTasks = await _firestore.getAdhocTasksForDate(DateTime.now());
  }

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

      // Init stats
      _stats = StatSnapshot(archetypeId: _archetype.id);
      await _firestore.saveStats(_stats);
    } catch (e, st) {
      Log.error(_tag, 'Failed to save onboarding profile', e, st);
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
      final quest = Quest(
        id: _uuid.v4(),
        programmeId: programmeId,
        title: qMap['title'] ?? '',
        description: qMap['description'] ?? '',
        primaryStat: qMap['primaryStat'] ?? 'discipline',
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
      final habit = Habit(
        id: _uuid.v4(),
        programmeId: programmeId,
        name: hMap['name'] ?? '',
        type: HabitType.values.firstWhere(
          (t) => t.name == hMap['type'],
          orElse: () => HabitType.checkbox,
        ),
        primaryStat: hMap['primaryStat'] ?? 'discipline',
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
    try {
      final existing = _todayCompletions
          .where((c) => c.habitId == habit.id)
          .firstOrNull;

      if (existing != null) {
        // Toggle off
        final updated = existing.copyWith(
          completed: !existing.completed,
          xpEarned: !existing.completed ? habit.baseXP : 0,
        );
        await _firestore.saveCompletion(updated);
        _todayCompletions = _todayCompletions
            .map((c) => c.id == updated.id ? updated : c)
            .toList();
      } else {
        // New completion
        final completion = Completion(
          id: _uuid.v4(),
          habitId: habit.id,
          programmeId: _programme?.id ?? '',
          date: DateTime.now(),
          completed: true,
          value: value,
          xpEarned: habit.baseXP,
        );
        await _firestore.saveCompletion(completion);
        _todayCompletions.add(completion);
      }

      // Update stats
      await _updateStats();
    } catch (e, st) {
      Log.error(_tag, 'Failed to toggle habit', e, st);
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }

  Future<void> addCompletionPhoto(String habitId, File photo) async {
    try {
      final existing = _todayCompletions
          .where((c) => c.habitId == habitId)
          .firstOrNull;
      if (existing == null) return;

      final url = await _storage.uploadCompletionPhoto(
        completionId: existing.id,
        file: photo,
      );

      final updated = existing.copyWith(photoUrl: url);
      await _firestore.saveCompletion(updated);
      _todayCompletions = _todayCompletions
          .map((c) => c.id == updated.id ? updated : c)
          .toList();
    } catch (e, st) {
      Log.error(_tag, 'Failed to upload photo', e, st);
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }

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

  Future<void> _updateStats() async {
    final gained = todayStatsGained;
    final newStats = Map<String, int>.from(_stats.stats);
    for (final entry in gained.entries) {
      newStats[entry.key] = (newStats[entry.key] ?? 0) + entry.value;
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

    _archetype = Archetype.calculate(newStats);

    _stats = _stats.copyWith(
      stats: newStats,
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
      photoUrls: _todayCompletions
          .where((c) => c.photoUrl != null)
          .map((c) => c.photoUrl!)
          .toList(),
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
      photoUrls:
          dailyWraps.expand((w) => w.photoUrls).toList(),
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
        final task = AdhocTask(
          id: _uuid.v4(),
          title: t['title'] as String? ?? '',
          voiceNoteId: noteId,
          completed: true, // user already did it
          primaryStat: t['primaryStat'] as String?,
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
    try {
      final updated = task.copyWith(completed: !task.completed);
      await _firestore.saveAdhocTask(updated);
      _todayAdhocTasks = _todayAdhocTasks
          .map((t) => t.id == updated.id ? updated : t)
          .toList();
    } catch (e, st) {
      Log.error(_tag, 'Failed to toggle task', e, st);
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }

  // ── Refresh ──

  Future<void> refreshTodayData() async {
    try {
      _todayAdhocTasks = await _firestore.getAdhocTasksForDate(DateTime.now());
      if (_programme != null) {
        _todayCompletions =
            await _firestore.getCompletionsForDate(DateTime.now());
        _stats = await _firestore.getStats();
        _archetype = Archetype.calculate(_stats.stats);
      }
    } catch (e, st) {
      Log.error(_tag, 'Failed to refresh data', e, st);
      _error = Log.friendlyMessage(e);
    }
    notifyListeners();
  }
}
