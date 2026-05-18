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
  GenerativeModel? _onboardingChatModel;
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
            'subSkillName': Schema.string(
              description:
                  'Primary sub-skill this quest develops, e.g. "Combat", "Endurance"',
            ),
            'subSkillDomain': Schema.enumString(
              enumValues: [
                'physical',
                'creative',
                'intellectual',
                'social',
                'discipline',
                'spiritual',
              ],
              description: 'Broad domain for this quest',
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
            'subSkillName': Schema.string(
              description:
                  'Specific skill this habit develops, e.g. "Combat", "Musical Ability", "Culinary Arts", "Public Speaking". Be specific and interesting — not generic like "Body" or "Mind".',
            ),
            'subSkillDomain': Schema.enumString(
              enumValues: [
                'physical',
                'creative',
                'intellectual',
                'social',
                'discipline',
                'spiritual',
              ],
              description: 'Which broad domain this sub-skill belongs to',
            ),
            'subSkillIcon': Schema.string(
              description:
                  'A single emoji that represents this specific sub-skill, e.g. 🥋 for combat, 🎹 for piano',
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
            'subSkillName': Schema.string(
              description:
                  'Specific skill this task develops, e.g. "Combat", "Cooking", "Running". Be specific.',
            ),
            'subSkillDomain': Schema.enumString(
              enumValues: [
                'physical',
                'creative',
                'intellectual',
                'social',
                'discipline',
                'spiritual',
              ],
              description: 'Broad domain this skill belongs to',
            ),
            'subSkillIcon': Schema.string(
              description: 'Single emoji for this skill, e.g. 🏃 for running',
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
            'subSkillName': Schema.string(
              description:
                  'Specific skill this task develops, e.g. "Running", "Sketching", "Cooking"',
            ),
            'subSkillDomain': Schema.enumString(
              enumValues: [
                'physical',
                'creative',
                'intellectual',
                'social',
                'discipline',
                'spiritual',
              ],
            ),
            'subSkillIcon': Schema.string(
              description: 'Single emoji for this skill',
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

  /// Onboarding chat model — thinking disabled so streaming chunks arrive
  /// immediately instead of waiting for the thinking phase to complete.
  GenerativeModel _getOnboardingChatModel() {
    return _onboardingChatModel ??= FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        thinkingConfig: ThinkingConfig.withThinkingBudget(0),
      ),
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
- Each habit and quest gets a SPECIFIC sub-skill name (e.g. "Combat" not "Body", "Musical Ability" not "Craft")
- Sub-skill domains: physical, creative, intellectual, social, discipline, spiritual
- Pick a fitting emoji icon for each sub-skill
- Each quest should have 2-4 phases
- baseXP for habits should be 5-20
- Habits must be ACTIONS the user actually DOES, not passive observations
- BAD habits: "Check bank balance", "Write down your weight", "Review your goals" — these are useless busywork
- GOOD habits: "Do 30 push-ups", "Read for 20 minutes", "No social media before noon", "Cook one healthy meal"
- Use the correct habit type: checkbox (do/don't do), abstinence (NOT doing something), timed (minutes spent), counter (reps/count)
- Every habit must pass the test: "Will doing this daily for 30 days actually change this person's life?"

PROVEN HABIT LIBRARY — select 4-6 from this list that best match the user's goals. Adapt specifics to their situation. Only create habits NOT in this library if their goals truly demand it.

MORNING ROUTINE:
- "Morning cold shower (2 min)" [checkbox, discipline, 15 XP]
- "10-minute morning meditation" [timed, targetValue: 10, spiritual, 10 XP]
- "Write 3 morning gratitudes" [checkbox, spiritual, 8 XP]
- "No phone for first 30 minutes" [abstinence, discipline, 10 XP]

PHYSICAL:
- "Do 30 push-ups" [counter, targetValue: 30, unit: reps, physical, 12 XP]
- "Run for 20 minutes" [timed, targetValue: 20, physical, 15 XP]
- "Walk 10,000 steps" [counter, targetValue: 10000, unit: steps, physical, 10 XP]
- "Full body stretch (10 min)" [timed, targetValue: 10, physical, 8 XP]

MIND & LEARNING:
- "Read for 20 minutes" [timed, targetValue: 20, intellectual, 10 XP]
- "Journal for 10 minutes" [timed, targetValue: 10, intellectual, 10 XP]
- "Learn one new thing (write it down)" [checkbox, intellectual, 8 XP]
- "Deep work session (45 min)" [timed, targetValue: 45, intellectual, 18 XP]

NUTRITION & HEALTH:
- "Cook one healthy meal from scratch" [checkbox, discipline, 12 XP]
- "No junk food" [abstinence, discipline, 10 XP]
- "Drink 8 glasses of water" [counter, targetValue: 8, unit: glasses, physical, 5 XP]
- "No alcohol" [abstinence, discipline, 12 XP]

DIGITAL WELLNESS & DISCIPLINE:
- "No social media after 9pm" [abstinence, discipline, 10 XP]
- "Screen time under 2 hours (non-work)" [abstinence, discipline, 12 XP]
- "No porn" [abstinence, discipline, 15 XP]

SLEEP:
- "In bed by 10:30pm" [checkbox, discipline, 10 XP]
- "No screens 30 min before bed" [abstinence, discipline, 8 XP]

CREATIVE:
- "Practise [skill] for 20 minutes" [timed, targetValue: 20, creative, 12 XP]
- "Write 500 words" [counter, targetValue: 500, unit: words, creative, 15 XP]

SOCIAL:
- "Reach out to one person" [checkbox, social, 8 XP]
- "Have one meaningful conversation (no phones)" [checkbox, social, 10 XP]

FINANCIAL:
- "Work on side project for 30 min" [timed, targetValue: 30, discipline, 15 XP]
- "Send 3 cold emails / outreach" [counter, targetValue: 3, unit: emails, discipline, 12 XP]''';

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
- Assign a specific sub-skill name (e.g. "Combat", "Running", "Cooking", "Public Speaking") — be specific, not generic
- Assign a broad domain (physical, creative, intellectual, social, discipline, spiritual)
- Pick a fitting emoji icon for the sub-skill
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

  // ── Streaming Methods ──

  /// Stream an onboarding response chunk-by-chunk.
  /// Uses a model with thinking disabled for instant streaming.
  Stream<String> streamOnboardingResponse({
    required String userName,
    required List<String> conversationHistory,
  }) async* {
    final model = _getOnboardingChatModel();

    // Separate system context (questionnaire data) from actual conversation
    final systemContext = conversationHistory
        .where((m) => m.startsWith('system_context:'))
        .join('\n');
    final chatHistory = conversationHistory
        .where((m) => !m.startsWith('system_context:'))
        .toList();

    final prompt =
        '''$_onboardingSystemPrompt

WHAT WE ALREADY KNOW (from questionnaire — DO NOT re-ask):
$systemContext

The user's name is $userName.

CONVERSATION SO FAR:
${chatHistory.isEmpty ? '(This is the start. Briefly acknowledge what you know from the questionnaire (1 sentence), then ask: "So — what do you want to achieve in the next 30 days? Dream big, be honest, say whatever comes to mind.")' : chatHistory.join('\n')}

${chatHistory.isNotEmpty ? 'Continue the conversation about their dream outcome. React to what they JUST said. When you have a clear goal, starting point, and picture of day 30, end your response with [READY_TO_BUILD].' : ''}''';

    final stream = model.generateContentStream([Content.text(prompt)]);
    await for (final chunk in stream) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  /// Stream a coach response chunk-by-chunk using Gemini's streaming API.
  Stream<String> streamCoachResponse({
    required String userMessage,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? activeProgramme,
    List<String> conversationHistory = const [],
  }) async* {
    final model = _getCoachModel();
    final prompt = _coachSystemPrompt(
      profile: profile,
      stats: stats,
      activeProgramme: activeProgramme,
      conversationHistory: conversationHistory,
      userMessage: userMessage,
    );

    final stream = model.generateContentStream([Content.text(prompt)]);
    await for (final chunk in stream) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  /// Stream an onboarding response from a voice message (audio sent to Gemini).
  /// Uses a model with thinking disabled for instant streaming.
  Stream<String> streamOnboardingResponseFromAudio({
    required File audioFile,
    required String userName,
    required List<String> conversationHistory,
  }) async* {
    Log.debug(_tag, 'Streaming onboarding voice response...');
    final model = _getOnboardingChatModel();
    final bytes = await audioFile.readAsBytes();

    final systemContext = conversationHistory
        .where((m) => m.startsWith('system_context:'))
        .join('\n');
    final chatHistory = conversationHistory
        .where((m) => !m.startsWith('system_context:'))
        .toList();

    final prompt =
        '''$_onboardingSystemPrompt

WHAT WE ALREADY KNOW (from questionnaire — DO NOT re-ask):
$systemContext

The user's name is $userName.

CONVERSATION SO FAR:
${chatHistory.isEmpty ? '(This is the start.)' : chatHistory.join('\n')}

The user just sent a voice message (audio above). Listen carefully and continue the conversation about their dream outcome. React to what they said. When you have a clear goal, starting point, and picture of day 30, end your response with [READY_TO_BUILD].''';

    final stream = model.generateContentStream([
      Content.multi([InlineDataPart('audio/mp4', bytes), TextPart(prompt)]),
    ]);
    await for (final chunk in stream) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  /// Stream a coach response from a voice message (audio sent to Gemini).
  Stream<String> streamCoachResponseFromAudio({
    required File audioFile,
    Map<String, dynamic>? profile,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? activeProgramme,
    List<String> conversationHistory = const [],
  }) async* {
    Log.debug(_tag, 'Streaming coach voice response...');
    final model = _getCoachModel();
    final bytes = await audioFile.readAsBytes();

    final stream = model.generateContentStream([
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
    await for (final chunk in stream) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) {
        yield text;
      }
    }
  }

  // ── Onboarding Conversation ──

  static const _onboardingSystemPrompt =
      '''You are Zenith, an AI life coach helping someone define their dream outcome for the next 30 days.

The user has ALREADY answered structured questions about their goal areas, pain points, and preferred activities. This context is provided below — DO NOT re-ask ANY of these.

Your job: Have a natural conversation about what they want to BECOME. Help them dream big, get specific, and feel excited about the next 30 days.

CONVERSATION FLOW:

1. FIRST MESSAGE: Briefly acknowledge what you know (1 sentence). Then ask: "So — what do you want to achieve in the next 30 days? Dream big, be honest, say whatever comes to mind."

2. AFTER THEY STATE THEIR GOAL: Help them paint the picture of their dream outcome.
   - If vague: "When you say '[goal]' — what does that actually look like at day 30? Paint me the picture."
   - If unrealistic: Don't shut them down. "Love that energy. What would a real first step toward that look like in 30 days?"
   - If specific: "That's great. What's your starting point right now?"
   - Keep it conversational — you're two people riffing on a vision, not filling out a form.

3. ONCE YOU HAVE ENOUGH: When you have a clear dream outcome and a sense of where they're starting from, end your response with the exact token [READY_TO_BUILD]. This signals the app to show the "Build my programme" button.

You have enough when you know:
- What they want to achieve (specific, not vague)
- Where they're starting from (current level/situation)
- What "done" looks like at day 30

This usually takes 2-4 exchanges. Don't drag it out.

RULES:
- Ask exactly ONE question per response
- Keep responses to 2-3 sentences max
- NEVER re-ask what the questionnaire already covered (goals, pain points, activities)
- Every question must be a DIRECT follow-up to what they just said
- Be encouraging but honest. If something isn't doable in 30 days, say so kindly.
- Help them think, don't think FOR them
- If they mention a skill: ask their current level and what success looks like
- If they mention fitness: ask for numbers
- If they mention money: ask what specifically
- Be direct. No therapy-speak. No filler.
- Never output JSON — just talk naturally
- Do NOT say "let me build your programme" — the app handles that via [READY_TO_BUILD]''';

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
${conversationHistory.isEmpty ? '(This is the start. Briefly acknowledge what you know, then ask what they want to achieve in the next 30 days.)' : conversationHistory.join('\n')}

${conversationHistory.isEmpty ? '' : 'Continue the conversation about their dream outcome. When you have a clear goal, starting point, and picture of day 30, end your response with [READY_TO_BUILD].'}''';

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

The user just sent a voice message (audio above). Listen to it and help them refine their 30-day goal.
${conversationHistory.length >= 8 ? 'You have enough info now. Wrap up and say something like "I think we\'ve got a solid 30-day goal and a clear plan. Let me build your programme."' : 'Help them think through what their goal requires day-to-day. React to their actual words.'}''';

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

CRITICAL RULES FOR HABITS:
- Generate exactly 2 quests and 4-6 daily habits
- Habits must be ACTIONS the user actually DOES, not passive observations
- BAD habits: "Check bank balance", "Write down your weight", "Review your goals" — these are useless busywork
- GOOD habits: "Do 30 push-ups", "Read for 20 minutes", "No social media before noon", "Cook one healthy meal", "Practise drawing for 15 minutes", "Cold shower", "Write 500 words"
- If the user wants to make money: habits should be DOING things that make money — "Work on side project for 30 min", "Send 3 cold emails", "Learn one new skill for 20 min" — NOT "check your bank account"
- If the user wants to break a bad habit: create an ABSTINENCE habit — "No porn", "No social media after 9pm", "No junk food"
- If the user wants to learn something: create PRACTICE habits — "Sketch 5 objects from life", "Practise guitar for 20 min", "Solve 3 coding problems"
- Every habit must pass the test: "Will doing this daily for 30 days actually change this person's life?" If the answer is no, don't include it.
- Use the correct habit type: checkbox (do/don't do), abstinence (NOT doing something), timed (minutes spent), counter (reps/count)
- For timed habits, set realistic targetValue in minutes
- For counter habits, set targetValue to a specific count
- baseXP: 5-20 based on difficulty

PROVEN HABIT LIBRARY — select 4-6 from this list that best match the user's goals. Adapt specifics to their situation. Only create habits NOT in this library if their goals truly demand it.

MORNING: "Morning cold shower (2 min)" [checkbox, discipline, 15 XP] | "10-minute morning meditation" [timed, 10, spiritual, 10 XP] | "Write 3 morning gratitudes" [checkbox, spiritual, 8 XP] | "No phone for first 30 minutes" [abstinence, discipline, 10 XP]
PHYSICAL: "Do 30 push-ups" [counter, 30, reps, physical, 12 XP] | "Run for 20 minutes" [timed, 20, physical, 15 XP] | "Walk 10,000 steps" [counter, 10000, steps, physical, 10 XP] | "Full body stretch (10 min)" [timed, 10, physical, 8 XP]
MIND: "Read for 20 minutes" [timed, 20, intellectual, 10 XP] | "Journal for 10 minutes" [timed, 10, intellectual, 10 XP] | "Deep work session (45 min)" [timed, 45, intellectual, 18 XP]
NUTRITION: "Cook one healthy meal" [checkbox, discipline, 12 XP] | "No junk food" [abstinence, discipline, 10 XP] | "Drink 8 glasses of water" [counter, 8, glasses, physical, 5 XP] | "No alcohol" [abstinence, discipline, 12 XP]
DIGITAL: "No social media after 9pm" [abstinence, discipline, 10 XP] | "Screen time under 2 hours" [abstinence, discipline, 12 XP] | "No porn" [abstinence, discipline, 15 XP]
SLEEP: "In bed by 10:30pm" [checkbox, discipline, 10 XP] | "No screens 30 min before bed" [abstinence, discipline, 8 XP]
CREATIVE: "Practise [skill] for 20 minutes" [timed, 20, creative, 12 XP] | "Write 500 words" [counter, 500, words, creative, 15 XP]
SOCIAL: "Reach out to one person" [checkbox, social, 8 XP] | "Have one meaningful conversation" [checkbox, social, 10 XP]
FINANCIAL: "Work on side project for 30 min" [timed, 30, discipline, 15 XP] | "Send 3 outreach emails" [counter, 3, emails, discipline, 12 XP]

OTHER RULES:
- focusPillars: 1-2 values from: body, mind, relationships, career, finances, growth
- Each habit and quest gets a SPECIFIC sub-skill name (e.g. "Combat" not "Body", "Sketching" not "Craft", "Running" not "Physical")
- Sub-skill domains: physical, creative, intellectual, social, discipline, spiritual
- DOMAIN MAPPING — assign the CORRECT domain for the user's goals:
  physical: running, gym, sports, yoga, martial arts, body challenges
  creative: drawing, painting, music, writing fiction, design, photography, film
  intellectual: reading, coding, learning languages, research, studying, system design
  social: relationships, networking, leadership, communication, mentoring
  discipline: routines, habits, time management, financial discipline, abstinence
  spiritual: meditation, mindfulness, journaling, self-reflection, breathwork
- Pick a fitting emoji for each sub-skill
- Each quest should have 2-4 phases with concrete daily actions
- Programme name should be inspiring and specific to THEIR goals, not generic''';

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
