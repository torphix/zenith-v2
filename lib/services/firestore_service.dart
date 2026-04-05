import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/adhoc_task.dart';
import '../models/assessment.dart';
import '../models/completion.dart';
import '../models/habit.dart';
import '../models/programme.dart';
import '../models/quest.dart';
import '../models/stat_snapshot.dart';
import '../models/user_profile.dart';
import '../models/voice_note.dart';
import '../models/wrap_data.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get uid => FirebaseAuth.instance.currentUser!.uid;
  DocumentReference get _userDoc => _db.collection('users').doc(uid);

  // ── User Profile ──

  Future<UserProfile?> getProfile() async {
    final doc = await _userDoc.get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _userDoc.set(profile.toMap(), SetOptions(merge: true));
  }

  Stream<UserProfile?> profileStream() {
    return _userDoc.snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
    });
  }

  // ── Assessment ──

  Future<void> saveAssessment(Assessment assessment) async {
    await _userDoc
        .collection('assessments')
        .doc(assessment.id)
        .set(assessment.toMap());
  }

  Future<Assessment?> getLatestAssessment() async {
    final snap = await _userDoc
        .collection('assessments')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Assessment.fromMap(snap.docs.first.data());
  }

  // ── Programme ──

  Future<void> saveProgramme(Programme programme) async {
    await _userDoc
        .collection('programmes')
        .doc(programme.id)
        .set(programme.toMap());
  }

  Future<Programme?> getActiveProgramme() async {
    final snap = await _userDoc
        .collection('programmes')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Programme.fromMap(snap.docs.first.data());
  }

  Stream<Programme?> activeProgrammeStream() {
    return _userDoc
        .collection('programmes')
        .where('isActive', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return Programme.fromMap(snap.docs.first.data());
    });
  }

  Future<void> deactivateProgramme(String programmeId) async {
    await _userDoc
        .collection('programmes')
        .doc(programmeId)
        .update({'isActive': false});
  }

  // ── Quests ──

  Future<void> saveQuest(Quest quest) async {
    await _userDoc.collection('quests').doc(quest.id).set(quest.toMap());
  }

  Future<List<Quest>> getQuestsForProgramme(String programmeId) async {
    final snap = await _userDoc
        .collection('quests')
        .where('programmeId', isEqualTo: programmeId)
        .get();
    return snap.docs.map((d) => Quest.fromMap(d.data())).toList();
  }

  // ── Habits ──

  Future<void> saveHabit(Habit habit) async {
    await _userDoc.collection('habits').doc(habit.id).set(habit.toMap());
  }

  Future<List<Habit>> getHabitsForProgramme(String programmeId) async {
    final snap = await _userDoc
        .collection('habits')
        .where('programmeId', isEqualTo: programmeId)
        .get();
    return snap.docs.map((d) => Habit.fromMap(d.data())).toList();
  }

  Stream<List<Habit>> habitsStream(String programmeId) {
    return _userDoc
        .collection('habits')
        .where('programmeId', isEqualTo: programmeId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Habit.fromMap(d.data())).toList());
  }

  // ── Completions ──

  Future<void> saveCompletion(Completion completion) async {
    await _userDoc
        .collection('completions')
        .doc(completion.id)
        .set(completion.toMap());
  }

  Future<List<Completion>> getCompletionsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _userDoc
        .collection('completions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs.map((d) => Completion.fromMap(d.data())).toList();
  }

  Future<List<Completion>> getCompletionsForProgramme(
      String programmeId) async {
    final snap = await _userDoc
        .collection('completions')
        .where('programmeId', isEqualTo: programmeId)
        .get();
    return snap.docs.map((d) => Completion.fromMap(d.data())).toList();
  }

  Stream<List<Completion>> completionsStreamForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _userDoc
        .collection('completions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map(
            (snap) => snap.docs.map((d) => Completion.fromMap(d.data())).toList());
  }

  // ── Stats ──

  Future<StatSnapshot> getStats() async {
    final doc = await _userDoc.collection('stats').doc('current').get();
    if (!doc.exists) return StatSnapshot();
    return StatSnapshot.fromMap(doc.data()!);
  }

  Future<void> saveStats(StatSnapshot stats) async {
    await _userDoc.collection('stats').doc('current').set(stats.toMap());
  }

  Stream<StatSnapshot> statsStream() {
    return _userDoc
        .collection('stats')
        .doc('current')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return StatSnapshot();
      return StatSnapshot.fromMap(doc.data()!);
    });
  }

  // ── Wraps ──

  Future<void> saveWrap(WrapData wrap) async {
    await _userDoc.collection('wraps').doc(wrap.id).set(wrap.toMap());
  }

  Future<WrapData?> getWrap(String wrapId) async {
    final doc = await _userDoc.collection('wraps').doc(wrapId).get();
    if (!doc.exists) return null;
    return WrapData.fromMap(doc.data()!);
  }

  Future<List<WrapData>> getWrapsOfType(String type, {int limit = 30}) async {
    final snap = await _userDoc
        .collection('wraps')
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => WrapData.fromMap(d.data())).toList();
  }

  // ── Voice Notes ──

  Future<void> saveVoiceNote(VoiceNote note) async {
    await _userDoc.collection('voiceNotes').doc(note.id).set(note.toMap());
  }

  // ── Ad-hoc Tasks ──

  Future<void> saveAdhocTask(AdhocTask task) async {
    await _userDoc.collection('adhocTasks').doc(task.id).set(task.toMap());
  }

  Future<List<AdhocTask>> getAdhocTasksForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _userDoc
        .collection('adhocTasks')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs.map((d) => AdhocTask.fromMap(d.data())).toList();
  }
}
