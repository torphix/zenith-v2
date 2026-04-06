import 'package:cloud_functions/cloud_functions.dart';

import 'ai_service.dart';

class FunctionsService {
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final _ai = AIService();

  /// Generate a programme using on-device Gemini (Firebase AI SDK).
  Future<Map<String, dynamic>> generateProgramme({
    required Map<String, int> assessmentScores,
    String? northStarVision,
    List<String> problems = const [],
    List<String> goals = const [],
    String commitmentLevel = '30',
    String energyPreference = 'balanced',
    int programmeNumber = 1,
  }) {
    return _ai.generateProgramme(
      assessmentScores: assessmentScores,
      northStarVision: northStarVision,
      problems: problems,
      goals: goals,
      commitmentLevel: commitmentLevel,
      energyPreference: energyPreference,
      programmeNumber: programmeNumber,
    );
  }

  Future<Map<String, dynamic>> parseNorthStar(String visionText) async {
    final callable = _functions.httpsCallable(
      'parseNorthStarVision',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final result = await callable.call({'visionText': visionText});
    return Map<String, dynamic>.from(result.data);
  }

  /// Coach response using on-device Gemini (Firebase AI SDK).
  Future<String> getCoachResponse({
    required String userMessage,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? activeProgramme,
    List<String> recentReflections = const [],
    List<String> conversationHistory = const [],
  }) {
    return _ai.getCoachResponse(
      userMessage: userMessage,
      profile: profile,
      stats: stats,
      activeProgramme: activeProgramme,
      conversationHistory: conversationHistory,
    );
  }

  /// Extract tasks from voice note using on-device Gemini.
  Future<List<Map<String, dynamic>>> processVoiceNote({
    required String transcript,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? activeProgramme,
  }) {
    return _ai.processVoiceNote(
      transcript: transcript,
      profile: profile,
      stats: stats,
      activeProgramme: activeProgramme,
    );
  }

  /// Transcribes an audio file URL to text.
  Future<String> transcribeAudio({required String audioUrl}) async {
    final callable = _functions.httpsCallable(
      'transcribeAudio',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final result = await callable.call({'audioUrl': audioUrl});
    return result.data['transcript'] as String? ?? '';
  }

  Future<Map<String, dynamic>> generateLifeReview({
    required String programmeId,
    required Map<String, dynamic> stats,
    List<String> reflections = const [],
  }) async {
    final callable = _functions.httpsCallable(
      'generateLifeReview',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    final result = await callable.call({
      'programmeId': programmeId,
      'stats': stats,
      'reflections': reflections,
    });
    return Map<String, dynamic>.from(result.data);
  }
}
