"""Zenith Cloud Functions — Python v2 (Gen 2)

Anthropic Claude callables: Zenith app programme generation (quests/habits),
North Star parsing, coach chat, plus legacy programme/review/goal flows.

Deploy: firebase deploy --only functions
Secret: firebase functions:secrets:set ANTHROPIC_API_KEY
"""

import json
import re
import uuid
from datetime import datetime, timezone

import anthropic
from firebase_admin import initialize_app
from firebase_functions import https_fn
from firebase_functions.options import set_global_options
from firebase_functions.params import SecretParam

# ── Config ──────────────────────────────────────────────────────────
set_global_options(max_instances=10, region="us-central1")
initialize_app()

ANTHROPIC_API_KEY = SecretParam("ANTHROPIC_API_KEY")
MODEL = "claude-sonnet-4-6"


def _call_claude(system: str, user: str, secret: SecretParam) -> str:
    """Send a prompt to Claude and return the text response."""
    client = anthropic.Anthropic(api_key=secret.value)
    message = client.messages.create(
        model=MODEL,
        max_tokens=8192,
        system=system,
        messages=[{"role": "user", "content": user}],
    )
    return message.content[0].text


def _extract_json(text: str) -> dict:
    """Extract JSON from Claude's response, handling markdown fences."""
    text = text.strip()
    if text.startswith("```"):
        lines = text.split("\n")
        lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        text = "\n".join(lines)
    text = text.strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        m = re.search(r"\{[\s\S]*\}", text)
        if m:
            return json.loads(m.group(0))
        raise


# ── Zenith app: programme JSON (quests / habits) — matches Flutter schema ──
@https_fn.on_call(
    timeout_sec=120,
    memory=512,
    secrets=[ANTHROPIC_API_KEY],
)
def generateZenithProgramme(req: https_fn.CallableRequest) -> dict:
    """Generate a 30-day programme (GeneratedProgramme shape) for the Flutter app."""
    data = req.data or {}
    scores = data.get("assessmentScores") or {}
    north_star = data.get("northStarVision")
    problems = data.get("problems") or []
    goals = data.get("goals") or []
    commitment = data.get("commitmentLevel", "")
    energy = data.get("energyPreference", "")
    programme_number = int(data.get("programmeNumber", 1))

    score_lines = "\n".join(f"  {k}: {v}" for k, v in scores.items())

    system = """You are Zenith, an AI life coach. You output ONLY valid JSON — no markdown,
no commentary, no code fences."""

    user = f"""Generate a personalized 30-day programme.

USER DATA:
- Life Assessment Scores (1-10):
{score_lines}

- North Star Vision: {north_star or "Not provided"}

- Problems they want to solve: {", ".join(problems) if problems else "None"}

- Goals they want to achieve: {", ".join(goals) if goals else "None"}

- Daily time commitment: {commitment}

- Energy preference: {energy} (affects coaching tone)

- Programme number: {programme_number} ({'This is their first programme - focus on foundations' if programme_number == 1 else f'They have completed {programme_number - 1} programmes - can be more ambitious'})

Based on their lowest scoring life pillars and stated goals, generate a programme.

Respond in this exact JSON format:
{{
  "name": "Programme name (2-4 words, inspiring)",
  "theme": "Brief theme (3-6 words)",
  "description": "2-3 sentences about what this programme will accomplish",
  "focusPillars": ["pillar1", "pillar2"],
  "quests": [
    {{
      "title": "Quest title",
      "description": "What this quest accomplishes",
      "primaryStat": "body|mind|knowledge|heart|discipline|craft",
      "phases": [
        {{
          "name": "Phase name",
          "description": "What happens in this phase",
          "dailyActions": ["Action 1", "Action 2"],
          "milestone": "What marks completion",
          "durationDays": 7
        }}
      ]
    }}
  ],
  "habits": [
    {{
      "name": "Habit name",
      "type": "checkbox|abstinence|timed|counter",
      "primaryStat": "body|mind|knowledge|heart|discipline|craft",
      "baseXP": 10,
      "targetValue": null,
      "unit": null
    }}
  ],
  "coachingNote": "A warm, personalized message introducing this programme"
}}

focusPillars: 1-2 values from: body, mind, relationships, career, finances, growth
Generate 2 quests and 4-6 habits. Ensure habits align with problems and goals.
primaryStat for quests and habits: body, mind, knowledge, heart, discipline, or craft only."""

    raw = _call_claude(system, user, ANTHROPIC_API_KEY)
    parsed = _extract_json(raw)
    return {"programme": parsed}


@https_fn.on_call(
    timeout_sec=60,
    memory=256,
    secrets=[ANTHROPIC_API_KEY],
)
def parseNorthStarVision(req: https_fn.CallableRequest) -> dict:
    """Parse a freeform vision into structured North Star fields (no visionStatement)."""
    data = req.data or {}
    vision = data.get("visionText", "").strip()
    if not vision:
        return {"identityStatement": None, "pillarGoals": {}, "keyMilestones": []}

    system = """You are Zenith, an AI life coach. You output ONLY valid JSON — no markdown."""

    user = f'''Parse this vision statement into structured components.

VISION: "{vision}"

Respond in this exact JSON format:
{{
  "identityStatement": "A 1-sentence 'I am...' statement capturing who they want to become",
  "pillarGoals": {{
    "body": "Their body/health goal if mentioned, or null",
    "mind": "Their mental/emotional goal if mentioned, or null",
    "relationships": "Their relationship goal if mentioned, or null",
    "career": "Their career/purpose goal if mentioned, or null",
    "finances": "Their financial goal if mentioned, or null",
    "growth": "Their learning/growth goal if mentioned, or null"
  }},
  "keyMilestones": ["3-month milestone", "6-month milestone", "12-month milestone"]
}}

Only include pillar goals that are actually mentioned or clearly implied.
Make milestones concrete and time-bound. Use JSON null for unused pillar goals.'''

    raw = _call_claude(system, user, ANTHROPIC_API_KEY)
    return _extract_json(raw)


@https_fn.on_call(
    timeout_sec=90,
    memory=512,
    secrets=[ANTHROPIC_API_KEY],
)
def generateCoachResponse(req: https_fn.CallableRequest) -> dict:
    """Coach chat reply as plain text."""
    data = req.data or {}
    user_message = data.get("userMessage", "")
    profile = data.get("profile") or {}
    stats = data.get("stats") or {}
    active = data.get("activeProgramme")
    reflections = data.get("recentReflections") or []
    history = data.get("conversationHistory") or []

    system = """You are Zenith, an AI life coach. Reply with helpful, concise coaching only.
No JSON. No preamble like "Here is my response"."""

    user = f"""USER CONTEXT (JSON):
{json.dumps(profile, indent=2)}

STATS:
{json.dumps(stats, indent=2)}

ACTIVE PROGRAMME:
{json.dumps(active, indent=2) if active else "null"}

RECENT REFLECTIONS:
{json.dumps(reflections, indent=2)}

CONVERSATION HISTORY:
{chr(10).join(history[-12:])}

USER MESSAGE: "{user_message}"

Respond as Zenith. Match the user's energy preference from the profile when possible.
Be concise (2-4 sentences unless more is needed). Reference their data when relevant.
Be warm but honest. Don't be preachy."""

    raw = _call_claude(system, user, ANTHROPIC_API_KEY)
    return {"reply": raw.strip()}


# ── 1. generateProgramme ───────────────────────────────────────────
@https_fn.on_call(
    timeout_sec=120,
    memory=512,
    secrets=[ANTHROPIC_API_KEY],
)
def generateProgramme(req: https_fn.CallableRequest) -> dict:
    """Generate a 30-day programme from onboarding data."""
    data = req.data
    onboarding = data["onboardingData"]
    programme_number = data.get("programmeNumber", 1)

    system = """You are Zenith, an elite AI life coach that creates personalised
30-day transformation programmes. You output ONLY valid JSON — no commentary."""

    user = f"""Create a 30-day programme (programme #{programme_number}) for this user:

Name: {onboarding.get("name", "User")}
Primary goal: {onboarding.get("primaryGoal", "")}
Secondary goals: {", ".join(onboarding.get("secondaryGoals", []))}
Self-assessment (1-10): {json.dumps(onboarding.get("selfAssessment", {{}}))}
Blockers: {", ".join(onboarding.get("blockers", []))}
WHY statement: {onboarding.get("whyStatement", "")}
Habits to break: {", ".join(onboarding.get("habitsToBreak", []))}
Daily minutes available: {onboarding.get("dailyMinutes", 30)}
Wake time: {onboarding.get("wakeTime", "07:00")}
Sleep time: {onboarding.get("sleepTime", "23:00")}

Return this exact JSON structure:
{{
  "programme": {{
    "id": "<uuid>",
    "userId": "",
    "programmeNumber": {programme_number},
    "title": "<inspiring programme title>",
    "createdAt": "<ISO 8601>",
    "startDate": "<ISO 8601>",
    "overallTheme": "<theme description>",
    "mantras": [
      {{
        "id": "<uuid>",
        "text": "<daily mantra>",
        "dayNumber": 1,
        "category": "<mind|body|spirit>"
      }}
      // ... one per day (30 total)
    ],
    "visualizationPrompts": [
      "<guided visualization prompt for day 1>",
      // ... 30 total
    ],
    "weeks": [
      {{
        "weekNumber": 1,
        "theme": "<week theme>",
        "challenge": "<weekly challenge description>",
        "days": [
          {{
            "dayNumber": 1,
            "habits": [
              {{
                "id": "<uuid>",
                "name": "<habit name>",
                "description": "<clear instruction>",
                "category": "mind",
                "frequency": "daily",
                "isKeystone": true,
                "emoji": "🧠",
                "targetMinutes": 10
              }}
            ],
            "mantraId": "<matching mantra id>",
            "visualizationPrompt": "<matching prompt>",
            "bonusChallenge": "<optional extra>"
          }}
          // ... 7 days per week
        ]
      }}
      // ... 4-5 weeks
    ]
  }}
}}

Rules:
- 3-5 habits per day, fitting within {onboarding.get("dailyMinutes", 30)} minutes total
- Each week should progressively build in intensity
- Categories: mind, body, spirit, productivity, social
- Make habits specific and actionable, not vague
- Include at least one keystone habit per day
- Mantras should be personal and reference the user's WHY
- Visualizations should be vivid and goal-oriented
- Generate valid UUIDs for all id fields"""

    raw = _call_claude(system, user, ANTHROPIC_API_KEY)
    result = _extract_json(raw)

    # Ensure userId is empty (client sets it)
    if "programme" in result:
        result["programme"]["userId"] = ""

    return result


# ── 2. generateLifeReview ──────────────────────────────────────────
@https_fn.on_call(
    timeout_sec=120,
    memory=512,
    secrets=[ANTHROPIC_API_KEY],
)
def generateLifeReview(req: https_fn.CallableRequest) -> dict:
    """Generate a narrative life review from programme stats."""
    data = req.data
    programme_id = data["programmeId"]
    stats = data["stats"]
    reflections = data.get("reflections", [])

    system = """You are Zenith, an empathetic AI life coach writing a deeply personal
end-of-programme review. You output ONLY valid JSON — no commentary."""

    user = f"""Write a life review based on this user's 30-day journey:

Programme ID: {programme_id}
Stats: {json.dumps(stats)}
User reflections: {json.dumps(reflections)}

Return this exact JSON:
{{
  "narrativeSummary": "<2-3 paragraph personal narrative of their journey>",
  "keyWins": ["<specific win 1>", "<win 2>", "<win 3>"],
  "areasForGrowth": ["<growth area 1>", "<growth area 2>"],
  "afterAssessment": {{
    "mind": <1-10>,
    "body": <1-10>,
    "discipline": <1-10>
  }}
}}

Rules:
- Reference specific stats (streak, completion %, habits completed)
- Be warm, encouraging, and specific — not generic
- Key wins should reference real achievements from their data
- Areas for growth should be constructive, not critical
- After assessment should reflect improvement from their efforts"""

    raw = _call_claude(system, user, ANTHROPIC_API_KEY)
    return _extract_json(raw)


# ── 3. generateProgrammeV2 ────────────────────────────────────────
@https_fn.on_call(
    timeout_sec=120,
    memory=512,
    secrets=[ANTHROPIC_API_KEY],
)
def generateProgrammeV2(req: https_fn.CallableRequest) -> dict:
    """Generate programme 2+ using onboarding data AND life review insights."""
    data = req.data
    onboarding = data["onboardingData"]
    review = data["lifeReviewData"]
    programme_number = data.get("programmeNumber", 2)

    system = """You are Zenith, an elite AI life coach creating the next evolution
of a user's transformation programme. You have their full history. Output ONLY valid JSON."""

    user = f"""Create programme #{programme_number} for this returning user:

ORIGINAL PROFILE:
Name: {onboarding.get("name", "User")}
Primary goal: {onboarding.get("primaryGoal", "")}
WHY: {onboarding.get("whyStatement", "")}
Daily minutes: {onboarding.get("dailyMinutes", 30)}

PREVIOUS PROGRAMME REVIEW:
Days completed: {review.get("totalDaysCompleted", 0)}
Habits completed: {review.get("totalHabitsCompleted", 0)}
Longest streak: {review.get("longestStreak", 0)}
Average daily score: {review.get("averageDailyScore", 0)}
Key wins: {json.dumps(review.get("keyWins", []))}
Areas for growth: {json.dumps(review.get("areasForGrowth", []))}
Before assessment: {json.dumps(review.get("beforeAssessment", {{}}))}
After assessment: {json.dumps(review.get("afterAssessment", {{}}))}
Narrative: {review.get("narrativeSummary", "")}

Return the same JSON structure as generateProgramme (see schema).
The programme should:
- Build on their progress and wins
- Address areas for growth
- Be noticeably harder/more ambitious than the previous programme
- Introduce new habits while keeping successful keystone habits
- Reference their journey so far in mantras

Return:
{{
  "programme": {{
    "id": "<uuid>",
    "userId": "",
    "programmeNumber": {programme_number},
    "title": "<title referencing evolution>",
    "createdAt": "<ISO 8601>",
    "startDate": "<ISO 8601>",
    "overallTheme": "<theme>",
    "mantras": [... 30 mantras ...],
    "visualizationPrompts": [... 30 prompts ...],
    "weeks": [... 4-5 weeks with days, habits, etc. ...]
  }}
}}

Use the same field structure as programme 1. Generate valid UUIDs."""

    raw = _call_claude(system, user, ANTHROPIC_API_KEY)
    result = _extract_json(raw)

    if "programme" in result:
        result["programme"]["userId"] = ""

    return result


# ── 4. parseCustomGoal ────────────────────────────────────────────
@https_fn.on_call(
    timeout_sec=60,
    memory=256,
    secrets=[ANTHROPIC_API_KEY],
)
def parseCustomGoal(req: https_fn.CallableRequest) -> dict:
    """Parse a freeform goal into a structured plan with habits and milestones."""
    data = req.data
    raw_input = data["rawInput"]
    daily_minutes = data.get("dailyMinutes", 30)
    current_level = data.get("currentLevel", "beginner")

    goal_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    system = """You are Zenith, an AI that transforms freeform goals into structured
30-day plans with daily habits and weekly milestones. Output ONLY valid JSON."""

    user = f"""Transform this goal into a structured 30-day plan:

Goal: "{raw_input}"
Current level: {current_level}
Daily time available: {daily_minutes} minutes

Return this exact JSON:
{{
  "customGoal": {{
    "id": "{goal_id}",
    "userId": "",
    "rawInput": "{raw_input}",
    "parsedTitle": "<clean, concise goal title>",
    "category": "<learning|fitness|creative|mindfulness|productivity|social>",
    "level": "{current_level}",
    "targetDays": 30,
    "masteryMetric": "<specific measurable outcome, e.g. 'Hold a 5-min conversation in Spanish'>",
    "isActive": true,
    "createdAt": "{now}",
    "milestones": [
      {{
        "weekNumber": 1,
        "description": "<what they should achieve by end of week 1>",
        "checkQuestion": "<yes/no question to verify milestone>",
        "completed": false
      }},
      {{
        "weekNumber": 2,
        "description": "<week 2 milestone>",
        "checkQuestion": "<verification question>",
        "completed": false
      }},
      {{
        "weekNumber": 3,
        "description": "<week 3 milestone>",
        "checkQuestion": "<verification question>",
        "completed": false
      }},
      {{
        "weekNumber": 4,
        "description": "<week 4 milestone>",
        "checkQuestion": "<verification question>",
        "completed": false
      }}
    ],
    "generatedHabits": [
      {{
        "id": "<uuid>",
        "name": "<daily activity name>",
        "description": "<specific instructions>",
        "category": "mind",
        "frequency": "daily",
        "isKeystone": true,
        "emoji": "<relevant emoji>",
        "targetMinutes": <minutes>
      }}
      // ... 3-5 habits that fit within {daily_minutes} minutes
    ]
  }}
}}

Rules:
- Parse the raw input into a clear, actionable title
- Milestones should progressively build (week 1 easiest → week 4 hardest)
- Check questions should be answerable with yes/no
- Habits should be specific daily activities, not vague
- Total habit minutes must fit within {daily_minutes} minutes
- Adjust difficulty based on level ({current_level})
- Mastery metric should be concrete and measurable
- Generate valid UUIDs for habit ids
- Category values for habits: mind, body, spirit, productivity, social"""

    raw = _call_claude(system, user, ANTHROPIC_API_KEY)
    result = _extract_json(raw)

    # Ensure IDs are set
    if "customGoal" in result:
        result["customGoal"]["id"] = goal_id
        result["customGoal"]["userId"] = ""
        result["customGoal"]["isActive"] = True

    return result
