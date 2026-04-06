import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import 'logger.dart';

const _tag = 'AIService';

class AIService {
  GenerativeModel? _programmeModel;
  GenerativeModel? _coachModel;
  GenerativeModel? _voiceNoteModel;

  /// Schema for programme generation structured output.
  static final _programmeSchema = Schema.object(
    properties: {
      'name': Schema.string(description: 'Programme name, 2-4 words, inspiring'),
      'theme': Schema.string(description: 'Brief theme, 3-6 words'),
      'description': Schema.string(
          description: '2-3 sentences about what this programme will accomplish'),
      'focusPillars': Schema.array(
        items: Schema.enumString(
          enumValues: ['body', 'mind', 'relationships', 'career', 'finances', 'growth'],
        ),
        description: '1-2 life pillars this programme focuses on',
      ),
      'coachingNote': Schema.string(
          description: 'A warm, personalized message introducing this programme'),
      'quests': Schema.array(
        items: Schema.object(
          properties: {
            'title': Schema.string(description: 'Quest title'),
            'description': Schema.string(description: 'What this quest accomplishes'),
            'primaryStat': Schema.enumString(
              enumValues: ['body', 'mind', 'knowledge', 'heart', 'discipline', 'craft'],
            ),
            'phases': Schema.array(
              items: Schema.object(
                properties: {
                  'name': Schema.string(description: 'Phase name'),
                  'description': Schema.string(description: 'What happens in this phase'),
                  'dailyActions': Schema.array(
                    items: Schema.string(),
                    description: 'Daily actions for this phase',
                  ),
                  'milestone': Schema.string(description: 'What marks completion'),
                  'durationDays': Schema.integer(description: 'Duration in days'),
                },
              ),
              description: 'Phases of this quest',
            ),
          },
        ),
        description: 'List of 2 quests',
      ),
      'habits': Schema.array(
        items: Schema.object(
          properties: {
            'name': Schema.string(description: 'Habit name'),
            'type': Schema.enumString(
              enumValues: ['checkbox', 'abstinence', 'timed', 'counter'],
            ),
            'primaryStat': Schema.enumString(
              enumValues: ['body', 'mind', 'knowledge', 'heart', 'discipline', 'craft'],
            ),
            'baseXP': Schema.integer(description: 'XP reward, typically 5-20'),
            'targetValue': Schema.integer(
              description: 'Target for timed/counter habits, null for checkbox/abstinence',
              nullable: true,
            ),
            'unit': Schema.string(
              description: 'Unit for timed/counter habits (minutes, reps, pages), null otherwise',
              nullable: true,
            ),
          },
        ),
        description: 'List of 4-6 daily habits',
      ),
    },
  );

  /// Schema for voice note task extraction.
  static final _voiceNoteSchema = Schema.object(
    properties: {
      'tasks': Schema.array(
        items: Schema.object(
          properties: {
            'title': Schema.string(description: 'Short task description'),
            'primaryStat': Schema.enumString(
              enumValues: ['body', 'mind', 'knowledge', 'heart', 'discipline', 'craft'],
              description: 'Which stat this task relates to',
            ),
            'xp': Schema.integer(description: 'XP reward 1-20 based on effort'),
          },
        ),
        description: 'Tasks extracted from the transcript',
      ),
    },
  );

  GenerativeModel _getProgrammeModel() {
    return _programmeModel ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _programmeSchema,
      ),
    );
  }

  GenerativeModel _getCoachModel() {
    return _coachModel ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
    );
  }

  GenerativeModel _getVoiceNoteModel() {
    return _voiceNoteModel ??= FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _voiceNoteSchema,
      ),
    );
  }

  /// Generate a personalised 30-day programme.
  Future<Map<String, dynamic>> generateProgramme({
    required Map<String, int> assessmentScores,
    String? northStarVision,
    List<String> problems = const [],
    List<String> goals = const [],
    String commitmentLevel = '30',
    String energyPreference = 'balanced',
    int programmeNumber = 1,
  }) async {
    final scoreLines =
        assessmentScores.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');

    final prompt = '''You are Zenith, an AI life coach generating a 30-day programme.

USER DATA:
- Life Assessment Scores (1-10):
$scoreLines

- North Star Vision: ${northStarVision ?? "Not provided"}

- Problems they want to solve: ${problems.isNotEmpty ? problems.join(", ") : "None"}

- Goals they want to achieve: ${goals.isNotEmpty ? goals.join(", ") : "None"}

- Daily time commitment: $commitmentLevel minutes

- Energy preference: $energyPreference (affects coaching tone)

- Programme number: $programmeNumber (${programmeNumber == 1 ? 'First programme - focus on foundations' : 'They have completed ${programmeNumber - 1} programmes - can be more ambitious'})

Based on their lowest scoring life pillars and stated goals, generate a programme.

Rules:
- focusPillars: 1-2 values from: body, mind, relationships, career, finances, growth
- Generate exactly 2 quests and 4-6 habits
- Ensure habits align with their problems and goals
- primaryStat for quests and habits must be: body, mind, knowledge, heart, discipline, or craft
- Each quest should have 2-4 phases
- baseXP for habits should be 5-20
- Make habits specific and actionable''';

    Log.debug(_tag, 'Generating programme...');
    final model = _getProgrammeModel();
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null) throw Exception('Empty response from AI');

    Log.debug(_tag, 'Programme generated successfully');
    final parsed = jsonDecode(text) as Map<String, dynamic>;
    return {'programme': parsed};
  }

  /// Get a coach response.
  Future<String> getCoachResponse({
    required String userMessage,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? activeProgramme,
    List<String> conversationHistory = const [],
  }) async {
    final prompt = '''You are Zenith, an AI life coach. Reply with helpful, concise coaching.
No JSON. No preamble like "Here is my response".

USER CONTEXT:
${jsonEncode(profile)}

STATS:
${jsonEncode(stats)}

ACTIVE PROGRAMME:
${activeProgramme != null ? jsonEncode(activeProgramme) : "null"}

CONVERSATION HISTORY:
${conversationHistory.take(12).join('\n')}

USER MESSAGE: "$userMessage"

Respond as Zenith. Match the user's energy preference from the profile when possible.
Be concise (2-4 sentences unless more is needed). Reference their data when relevant.
Be warm but honest. Don't be preachy.''';

    final model = _getCoachModel();
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text?.trim() ?? 'I\'m here for you. Let\'s talk.';
  }

  /// Extract tasks from a voice note transcript.
  Future<List<Map<String, dynamic>>> processVoiceNote({
    required String transcript,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? activeProgramme,
  }) async {
    final prompt = '''Extract actionable tasks from this voice note transcript.

TRANSCRIPT: "$transcript"

USER CONTEXT:
${jsonEncode(profile)}

STATS:
${jsonEncode(stats)}

ACTIVE PROGRAMME:
${activeProgramme != null ? jsonEncode(activeProgramme) : "null"}

Rules:
- Extract 1-5 tasks mentioned in the transcript
- Each task should be a short, clear description
- Assign a primaryStat (body, mind, knowledge, heart, discipline, craft) based on the task
- Assign XP between 1-20 based on effort level''';

    final model = _getVoiceNoteModel();
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null) return [];

    final parsed = jsonDecode(text) as Map<String, dynamic>;
    final tasks = parsed['tasks'] as List? ?? [];
    return tasks.cast<Map<String, dynamic>>();
  }
}
