/// Holds all user responses collected during onboarding.
class OnboardingData {
  String name = '';
  List<String> selectedGoals = [];
  List<String> selectedPainPoints = [];
  List<String> selectedPreferences = [];
  String commitmentLevel = '30';
  String energyPreference = 'balanced';
  List<String> conversationHistory = [];

  /// Builds a context summary for the AI conversation screen.
  String get contextSummary {
    final parts = <String>[];
    if (selectedGoals.isNotEmpty) {
      parts.add('Goals: ${selectedGoals.join(", ")}');
    }
    if (selectedPainPoints.isNotEmpty) {
      parts.add('Pain points: ${selectedPainPoints.join(", ")}');
    }
    if (selectedPreferences.isNotEmpty) {
      parts.add('Preferences: ${selectedPreferences.join(", ")}');
    }
    parts.add('Commitment: $commitmentLevel min/day');
    parts.add('Energy: $energyPreference');
    return parts.join('\n');
  }
}
