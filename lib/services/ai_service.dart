import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';

import 'logger.dart';

/// Recursively converts a map to be JSON-safe (Timestamps → ISO strings).
dynamic _jsonSafe(dynamic value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  if (value is DateTime) return value.toIso8601String();
  if (value is Map) return value.map((k, v) => MapEntry(k, _jsonSafe(v)));
  if (value is List) return value.map(_jsonSafe).toList();
  return value;
}

String _safeEncode(dynamic value) => jsonEncode(_jsonSafe(value));

const _tag = 'AIService';

class AIService {
  GenerativeModel? _programmeModel;
  GenerativeModel? _coachModel;
  GenerativeModel? _voiceNoteModel;
  GenerativeModel? _lifeReviewModel;

  /// Schema for programme generation structured output.
  static final _programmeSchema = Schema.object(
    properties: {
      'name': Schema.string(
        description: 'Programme name, 2-4 words, inspiring',
      ),
      'theme': Schema.string(description: 'Brief theme, 3-6 words'),
      'description': Schema.string(
        description: '2-3 sentences about what this programme will accomplish',
      ),
      'focusPillars': Schema.array(
        items: Schema.enumString(
          enumValues: [
            'body',
            'mind',
            'relationships',
            'career',
            'finances',
            'growth',
          ],
        ),
        description: '1-2 life pillars this programme focuses on',
      ),
      'coachingNote': Schema.string(
        description: 'A warm, personalized message introducing this programme',
      ),
      'quests': Schema.array(
        items: Schema.object(
          properties: {
            'title': Schema.string(description: 'Quest title'),
            'description': Schema.string(
              description: 'What this quest accomplishes',
            ),
            'primaryStat': Schema.enumString(
              enumValues: [
                'body',
                'mind',
                'knowledge',
                'heart',
                'discipline',
                'craft',
              ],
            ),
            'phases': Schema.array(
              items: Schema.object(
                properties: {
                  'name': Schema.string(description: 'Phase name'),
                  'description': Schema.string(
                    description: 'What happens in this phase',
                  ),
                  'dailyActions': Schema.array(
                    items: Schema.string(),
                    description: 'Daily actions for this phase',
                  ),
                  'milestone': Schema.string(
                    description: 'What marks completion',
                  ),
                  'durationDays': Schema.integer(
                    description: 'Duration in days',
                  ),
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
              enumValues: [
                'body',
                'mind',
                'knowledge',
                'heart',
                'discipline',
                'craft',
              ],
            ),
            'baseXP': Schema.integer(description: 'XP reward, typically 5-20'),
            'targetValue': Schema.integer(
              description:
                  'Target for timed/counter habits, null for checkbox/abstinence',
              nullable: true,
            ),
            'unit': Schema.string(
              description:
                  'Unit for timed/counter habits (minutes, reps, pages), null otherwise',
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
              enumValues: [
                'body',
                'mind',
                'knowledge',
                'heart',
                'discipline',
                'craft',
              ],
              description: 'Which stat this task relates to',
            ),
            'xp': Schema.integer(description: 'XP reward 1-20 based on effort'),
          },
        ),
        description: 'Tasks extracted from the audio',
      ),
    },
  );

  /// Schema for life review structured output.
  static final _lifeReviewSchema = Schema.object(
    properties: {
      'narrativeSummary': Schema.string(
        description: '2-3 paragraph personal narrative of their journey',
      ),
      'keyWins': Schema.array(
        items: Schema.string(),
        description: '3 specific wins from their data',
      ),
      'areasForGrowth': Schema.array(
        items: Schema.string(),
        description: '2 constructive growth areas',
      ),
      'afterAssessment': Schema.object(
        properties: {
          'mind': Schema.integer(description: 'Score 1-10'),
          'body': Schema.integer(description: 'Score 1-10'),
          'discipline': Schema.integer(description: 'Score 1-10'),
        },
      ),
    },
  );

  /// Schema for extracting a full user profile from an onboarding conversation.
  static final _onboardingProfileSchema = Schema.object(
    properties: {
      'assessmentScores': Schema.object(
        properties: {
          'body': Schema.integer(description: 'Body & health score 1-10'),
          'mind': Schema.integer(description: 'Mental wellbeing score 1-10'),
          'relationships': Schema.integer(
            description: 'Relationships score 1-10',
          ),
          'career': Schema.integer(description: 'Career & purpose score 1-10'),
          'finances': Schema.integer(description: 'Finances score 1-10'),
          'growth': Schema.integer(description: 'Personal growth score 1-10'),
        },
        description: 'Inferred life assessment scores from conversation',
      ),
      'problems': Schema.array(
        items: Schema.string(),
        description: 'Key problems/struggles mentioned',
      ),
      'goals': Schema.array(
        items: Schema.string(),
        description: 'Goals and aspirations mentioned',
      ),
      'northStarVision': Schema.string(
        description:
            'A synthesized vision statement of who they want to become',
        nullable: true,
      ),
      'energyPreference': Schema.enumString(
        enumValues: ['gentle', 'balanced', 'intense'],
        description:
            'Inferred coaching style preference from tone of conversation',
      ),
      'commitmentLevel': Schema.enumString(
        enumValues: ['15', '30', '45', '60'],
        description: 'Daily minutes they can commit, inferred or stated',
      ),
    },
  );

  /// Schema for starter tasks from north star vision.
  static final _starterTasksSchema = Schema.object(
    properties: {
      'tasks': Schema.array(
        items: Schema.object(
          properties: {
            'title': Schema.string(
              description: 'Short actionable task for today',
            ),
            'primaryStat': Schema.enumString(
              enumValues: [
                'body',
                'mind',
                'knowledge',
                'heart',
                'discipline',
                'craft',
              ],
            ),
            'xp': Schema.integer(description: 'XP reward 5-15'),
          },
        ),
        description: '3-5 starter tasks based on vision',
      ),
    },
  );

  GenerativeModel _getProgrammeModel() {
    return _programmeModel ??= FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _programmeSchema,
      ),
    );
  }

  GenerativeModel _getCoachModel() {
    return _coachModel ??= FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.5-flash',
    );
  }

  GenerativeModel _getVoiceNoteModel() {
    return _voiceNoteModel ??= FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _voiceNoteSchema,
      ),
    );
  }

  GenerativeModel _getLifeReviewModel() {
    return _lifeReviewModel ??= FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _lifeReviewSchema,
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
    final scoreLines = assessmentScores.entries
        .map((e) => '  ${e.key}: ${e.value}')
        .join('\n');

    final prompt =
        '''You are Zenith, an AI life coach generating a 30-day programme.

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

  /// Get a text coach response.
  Future<String> getCoachResponse({
    required String userMessage,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? activeProgramme,
    List<String> conversationHistory = const [],
  }) async {
    final model = _getCoachModel();
    final response = await model.generateContent([
      Content.text(
        _coachSystemPrompt(
          profile: profile,
          stats: stats,
          activeProgramme: activeProgramme,
          conversationHistory: conversationHistory,
          userMessage: userMessage,
        ),
      ),
    ]);
    return response.text?.trim() ?? 'I\'m here for you. Let\'s talk.';
  }

  /// Get a coach response from a voice message — sends audio straight to Gemini.
  Future<String> getCoachResponseFromAudio({
    required File audioFile,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? activeProgramme,
    List<String> conversationHistory = const [],
  }) async {
    Log.debug(_tag, 'Sending voice to coach...');
    final model = _getCoachModel();
    final bytes = await audioFile.readAsBytes();

    final response = await model.generateContent([
      Content.multi([
        InlineDataPart('audio/mp4', bytes),
        TextPart(
          _coachSystemPrompt(
            profile: profile,
            stats: stats,
            activeProgramme: activeProgramme,
            conversationHistory: conversationHistory,
            userMessage: '[Voice message — listen to the audio above]',
          ),
        ),
      ]),
    ]);
    return response.text?.trim() ?? 'I\'m here for you. Let\'s talk.';
  }

  /// Extract tasks directly from voice audio — no transcription step.
  Future<List<Map<String, dynamic>>> processVoiceNoteAudio({
    required File audioFile,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? activeProgramme,
  }) async {
    Log.debug(_tag, 'Processing voice note audio...');
    final model = _getVoiceNoteModel();
    final bytes = await audioFile.readAsBytes();

    final response = await model.generateContent([
      Content.multi([
        InlineDataPart('audio/mp4', bytes),
        TextPart(
          '''Listen to this voice note and extract actionable tasks the user mentions.

USER CONTEXT:
${_safeEncode(profile)}

STATS:
${_safeEncode(stats)}

ACTIVE PROGRAMME:
${activeProgramme != null ? _safeEncode(activeProgramme) : "null"}

Rules:
- Extract 1-5 tasks mentioned in the audio
- Each task should be a short, clear description
- Assign a primaryStat (body, mind, knowledge, heart, discipline, craft) based on the task
- Assign XP between 1-20 based on effort level''',
        ),
      ]),
    ]);

    final text = response.text;
    if (text == null) return [];

    final parsed = jsonDecode(text) as Map<String, dynamic>;
    final tasks = parsed['tasks'] as List? ?? [];
    return tasks.cast<Map<String, dynamic>>();
  }

  /// Generate a life review from programme stats.
  Future<Map<String, dynamic>> generateLifeReview({
    required String programmeId,
    required Map<String, dynamic> stats,
    List<String> reflections = const [],
  }) async {
    final prompt =
        '''Write a life review based on this user's 30-day journey:

Programme ID: $programmeId
Stats: ${_safeEncode(stats)}
User reflections: ${_safeEncode(reflections)}

Rules:
- Reference specific stats (streak, completion %, habits completed)
- Be warm, encouraging, and specific - not generic
- Key wins should reference real achievements from their data
- Areas for growth should be constructive, not critical
- After assessment should reflect improvement from their efforts''';

    Log.debug(_tag, 'Generating life review...');
    final model = _getLifeReviewModel();
    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null) throw Exception('Empty response from AI');

    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// Generate starter tasks from the user's north star vision and goals.
  Future<List<Map<String, dynamic>>> generateStarterTasks({
    required String northStarVision,
    required List<String> goals,
    required List<String> problems,
  }) async {
    Log.debug(_tag, 'Generating starter tasks from vision...');
    final model = FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _starterTasksSchema,
      ),
    );

    final prompt =
        '''The user just described their ideal self in one year:

"$northStarVision"

Their goals: ${goals.join(', ')}
Their struggles: ${problems.join(', ')}

Generate 3-5 small, actionable tasks they can do TODAY to start becoming that person.
Tasks should be concrete and completable in under 30 minutes each.
Examples: "Do 20 push-ups", "Read for 15 minutes", "Write 3 things you're grateful for".
Don't be generic — tailor to their specific vision and goals.''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null) return [];

    final parsed = jsonDecode(text) as Map<String, dynamic>;
    final tasks = parsed['tasks'] as List? ?? [];
    return tasks.cast<Map<String, dynamic>>();
  }

  // ── Onboarding Conversation ──

  static const _onboardingSystemPrompt =
      '''You are Zenith, an AI life coach conducting an onboarding conversation.
Your goal is to learn about the user so you can build them a personalised 30-day programme.

You need to understand:
1. Where they are in life right now (health, mental state, relationships, career, finances, growth)
2. What they're struggling with
3. What they want to achieve / who they want to become
4. How much time they can commit daily

Guidelines:
- Ask ONE question at a time
- Be warm, direct, and conversational — not clinical or preachy
- Keep responses to 2-3 sentences max
- Adapt your follow-ups based on what they share
- If they mention something emotional, acknowledge it before moving on
- Don't ask more than 6 questions total — you should have enough info by then
- Never output JSON or structured data — just talk naturally''';

  /// Get the next onboarding question based on conversation so far.
  /// Pass the full history as alternating user/assistant Content objects.
  Future<String> getOnboardingResponse({
    required String userName,
    required List<String> conversationHistory,
  }) async {
    final model = _getCoachModel();

    final prompt =
        '''$_onboardingSystemPrompt

The user's name is $userName.

CONVERSATION SO FAR:
${conversationHistory.isEmpty ? '(This is the start — greet them and ask your first question about their life.)' : conversationHistory.join('\n')}

${conversationHistory.isEmpty ? '' : 'Continue the conversation. Ask your next question based on what you\'ve learned so far. If you have enough info after ~5-6 exchanges, say something like "I think I have a great picture of where you are and where you want to go. Let me build your programme." — this signals you are done.'}''';

    final response = await model.generateContent([Content.text(prompt)]);
    return response.text?.trim() ??
        'Tell me about yourself — where are you at in life right now?';
  }

  /// Same as above but the user sent a voice message.
  Future<String> getOnboardingResponseFromAudio({
    required File audioFile,
    required String userName,
    required List<String> conversationHistory,
  }) async {
    Log.debug(_tag, 'Processing onboarding voice...');
    final model = _getCoachModel();
    final bytes = await audioFile.readAsBytes();

    final prompt =
        '''$_onboardingSystemPrompt

The user's name is $userName.

CONVERSATION SO FAR:
${conversationHistory.isEmpty ? '(This is the start.)' : conversationHistory.join('\n')}

The user just sent a voice message (audio above). Listen to it and continue the conversation.
${conversationHistory.length >= 8 ? 'You have enough info now. Wrap up and say something like "I think I have a great picture of where you are and where you want to go. Let me build your programme."' : 'Ask your next question based on what you\'ve learned.'}''';

    final response = await model.generateContent([
      Content.multi([InlineDataPart('audio/mp4', bytes), TextPart(prompt)]),
    ]);
    return response.text?.trim() ?? 'Tell me more about that.';
  }

  /// Extract a structured profile from the full onboarding conversation.
  Future<Map<String, dynamic>> extractOnboardingProfile({
    required String userName,
    required List<String> conversationHistory,
  }) async {
    Log.debug(_tag, 'Extracting profile from conversation...');
    final model = FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: _onboardingProfileSchema,
      ),
    );

    final prompt =
        '''Analyze this onboarding conversation and extract a structured user profile.

USER NAME: $userName

CONVERSATION:
${conversationHistory.join('\n')}

Based on what was discussed, infer:
- assessmentScores: rate each life pillar 1-10 based on what they shared
- problems: list their key struggles
- goals: list their aspirations
- northStarVision: synthesize a vision statement of who they want to become
- energyPreference: infer from their communication style (gentle/balanced/intense)
- commitmentLevel: if mentioned, otherwise default to "30"

Be generous but honest with scores. If a topic wasn't discussed, give a neutral 5.''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null) throw Exception('Failed to extract profile');

    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// Generate programme directly from conversation transcript (single call).
  Future<Map<String, dynamic>> generateProgrammeFromConversation({
    required String userName,
    required List<String> conversationHistory,
    required Map<String, dynamic> extractedProfile,
    int programmeNumber = 1,
  }) async {
    Log.debug(_tag, 'Generating programme from conversation...');
    final model = _getProgrammeModel();

    final prompt =
        '''You are Zenith, an AI life coach generating a 30-day programme.

USER: $userName

ONBOARDING CONVERSATION:
${conversationHistory.join('\n')}

EXTRACTED PROFILE:
${_safeEncode(extractedProfile)}

Programme number: $programmeNumber (${programmeNumber == 1 ? 'First programme - focus on foundations' : 'Returning user'})

Based on the REAL conversation above, generate a deeply personalized programme.
Reference specific things the user mentioned. Make it feel like you listened.

Rules:
- focusPillars: 1-2 values from: body, mind, relationships, career, finances, growth
- Generate exactly 2 quests and 4-6 habits
- primaryStat: body, mind, knowledge, heart, discipline, or craft
- Each quest should have 2-4 phases
- baseXP for habits should be 5-20
- Make habits specific and actionable — tied to what they actually said''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text;
    if (text == null) throw Exception('Empty response from AI');

    final parsed = jsonDecode(text) as Map<String, dynamic>;
    return {'programme': parsed};
  }

  String _coachSystemPrompt({
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? activeProgramme,
    List<String> conversationHistory = const [],
    required String userMessage,
  }) {
    return '''You are Zenith, an AI life coach. Reply with helpful, concise coaching.
No JSON. No preamble like "Here is my response".

USER CONTEXT:
${_safeEncode(profile)}

STATS:
${_safeEncode(stats)}

ACTIVE PROGRAMME:
${activeProgramme != null ? _safeEncode(activeProgramme) : "null"}

CONVERSATION HISTORY:
${conversationHistory.take(12).join('\n')}

USER MESSAGE: "$userMessage"

Respond as Zenith. Match the user's energy preference from the profile when possible.
Be concise (2-4 sentences unless more is needed). Reference their data when relevant.
Be warm but honest. Don't be preachy.''';
  }
}
