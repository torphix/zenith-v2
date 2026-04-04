import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<Map<String, dynamic>> generateProgramme({
    required Map<String, int> assessmentScores,
    String? northStarVision,
    List<String> problems = const [],
    List<String> goals = const [],
    String commitmentLevel = '30',
    String energyPreference = 'balanced',
    int programmeNumber = 1,
  }) async {
    final callable = _functions.httpsCallable(
      'generateZenithProgramme',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
    );
    final result = await callable.call({
      'assessmentScores': assessmentScores,
      'northStarVision': northStarVision,
      'problems': problems,
      'goals': goals,
      'commitmentLevel': commitmentLevel,
      'energyPreference': energyPreference,
      'programmeNumber': programmeNumber,
    });
    return Map<String, dynamic>.from(result.data);
  }

  Future<Map<String, dynamic>> parseNorthStar(String visionText) async {
    final callable = _functions.httpsCallable(
      'parseNorthStarVision',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
    );
    final result = await callable.call({'visionText': visionText});
    return Map<String, dynamic>.from(result.data);
  }

  Future<String> getCoachResponse({
    required String userMessage,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? activeProgramme,
    List<String> recentReflections = const [],
    List<String> conversationHistory = const [],
  }) async {
    final callable = _functions.httpsCallable(
      'generateCoachResponse',
      options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
    );
    final result = await callable.call({
      'userMessage': userMessage,
      'profile': profile,
      'stats': stats,
      'activeProgramme': activeProgramme,
      'recentReflections': recentReflections,
      'conversationHistory': conversationHistory,
    });
    return result.data['reply'] as String;
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
