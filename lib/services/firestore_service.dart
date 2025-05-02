import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/class.dart';
import '../models/task.dart';
import 'package:rxdart/rxdart.dart';

/// Modular FirestoreService for all Firestore operations.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get students for a class-section from student_master/{schoolCode}/{classId}/students
  Future<List<Student>> getStudents(String schoolCode, String classId) async {
    final snapshot = await _db
        .collection('student_master')
        .doc(schoolCode)
        .collection(classId)
        .doc('students')
        .get();
    if (!snapshot.exists) return [];
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null || data['students'] == null) return [];
    return List<Map<String, dynamic>>.from(data['students'])
        .map((s) => Student.fromMap(s))
        .toList();
  }

  /// Save students for a class-section under student_master/{schoolCode}/{classId}/students
  Future<void> saveStudents(String schoolCode, String classId, List<Student> students) async {
    await _db
        .collection('student_master')
        .doc(schoolCode)
        .collection(classId)
        .doc('students')
        .set({'students': students.map((s) => s.toMap()).toList()}, SetOptions(merge: true));
  }

  // Get class details
  Future<SchoolClass?> getClass(String schoolCode, String className) async {
    final doc = await _db
        .collection('school_classes')
        .doc(schoolCode)
        .collection('classesData')
        .doc(className)
        .get();
    if (!doc.exists) return null;
    return SchoolClass.fromMap(doc.data()!);
  }

  // Save/update class details (partial merge)
  Future<void> saveClass(String schoolCode, SchoolClass schoolClass) async {
    await _db
        .collection('school_classes')
        .doc(schoolCode)
        .collection('classesData')
        .doc(schoolClass.className)
        .set(schoolClass.toMap(), SetOptions(merge: true));
  }

  // Save or update a class with createdBy field
  Future<void> saveClassWithCreator(String schoolCode, SchoolClass schoolClass, String createdBy, String teacherName, {String? docId}) async {
    final id = docId ?? schoolClass.className;
    await _db.collection('school_classes')
      .doc(schoolCode)
      .collection('classesData')
      .doc(id)
      .set({
        ...schoolClass.toMap(),
        'createdBy': createdBy,
        'classTeacherName': teacherName,
        'createdAt': FieldValue.serverTimestamp(),
        'schoolCode': schoolCode,
      }, SetOptions(merge: true));
  }

  // Get tasks for a user
  Future<List<Task>> getTasks(String schoolCode, String userId) async {
    final snapshot = await _db
        .collection('tasks')
        .where('schoolCode', isEqualTo: schoolCode)
        .where('assignedTo', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => Task.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Save or update a task
  Future<void> saveTask(Task task) async {
    await _db.collection('tasks').doc(task.id).set(task.toMap(), SetOptions(merge: true));
  }

  // Stream all users
  Stream<QuerySnapshot> usersStream() {
    return _db.collection('users').snapshots();
  }

  // Save or update a user's role and email
  Future<void> saveUserRole(String uid, String role, String? email) async {
    await _db.collection('users').doc(uid).set({
      'role': role,
      if (email != null) 'email': email,
      'uid': uid,
    }, SetOptions(merge: true));
  }

  // Set isClassCreated for a user
  Future<void> setUserClassCreated(String uid, bool value) async {
    await _db.collection('users').doc(uid).set({
      'isClassCreated': value,
    }, SetOptions(merge: true));
  }

  // Stream for teachers in a school (for count/statistics)
  Stream<QuerySnapshot> teacherCountStream(String schoolCode) {
    return _db.collection('group_member')
      .where('role', isEqualTo: 'teacher')
      .where('schoolCode', isEqualTo: schoolCode)
      .snapshots();
  }

  /// Fetch teacher onboarding status: returns {isClassCreated, teacherName, groupMemberDocId}
  Future<Map<String, dynamic>> getTeacherOnboardingStatus(String uid) async {
    // Fetch isClassCreated from users
    final userDoc = await _db.collection('users').doc(uid).get();
    final isClassCreated = (userDoc.data()?['isClassCreated'] ?? false) == true;
    // Fetch teacherName from group_member
    final gmSnap = await _db.collection('group_member').where('userId', isEqualTo: uid).limit(1).get();
    String? teacherName;
    String? groupMemberDocId;
    if (gmSnap.docs.isNotEmpty) {
      teacherName = gmSnap.docs.first.data()['name'];
      groupMemberDocId = gmSnap.docs.first.id;
    }
    return {
      'isClassCreated': isClassCreated,
      'teacherName': teacherName,
      'groupMemberDocId': groupMemberDocId,
    };
  }

  /// Mark teacher as onboarded in group_member
  Future<void> setTeacherOnboarded(String groupMemberDocId) async {
    await _db.collection('group_member').doc(groupMemberDocId).set({
      'onboarded': true,
    }, SetOptions(merge: true));
  }

  /// Check if the teacher has created any class (by createdBy field)
  Future<bool> hasTeacherCreatedClass(String uid, String schoolCode) async {
    final classesSnap = await _db.collection('school_classes')
      .doc(schoolCode)
      .collection('classesData')
      .where('createdBy', isEqualTo: uid)
      .limit(1)
      .get();
    return classesSnap.docs.isNotEmpty;
  }

  /// Centralized check: should the onboarding dialog be shown for this teacher?
  Future<bool> shouldShowTeacherOnboarding(String uid) async {
    // Fetch user data
    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};
    final isClassCreated = (userData['isClassCreated'] ?? false) == true;
    final schoolCode = userData['schoolCode'] ?? '';
    // Fetch group_member
    final gmSnap = await _db.collection('group_member').where('userId', isEqualTo: uid).limit(1).get();
    String? teacherName;
    bool onboarded = false;
    if (gmSnap.docs.isNotEmpty) {
      teacherName = gmSnap.docs.first.data()['name'];
      onboarded = gmSnap.docs.first.data()['onboarded'] == true;
    }
    // Check if teacher has created any class
    bool hasCreatedClass = false;
    if (schoolCode != null && schoolCode.toString().isNotEmpty) {
      final classesSnap = await _db.collection('school_classes')
        .doc(schoolCode)
        .collection('classesData')
        .where('createdBy', isEqualTo: uid)
        .limit(1)
        .get();
      hasCreatedClass = classesSnap.docs.isNotEmpty;
    }
    // Debug prints
    print('[OnboardingCheck] uid=$uid, teacherName=$teacherName, isClassCreated=$isClassCreated, onboarded=$onboarded, hasCreatedClass=$hasCreatedClass, schoolCode=$schoolCode');
    // Decision logic
    if (onboarded) return false;
    if (teacherName != null && teacherName.trim().isNotEmpty && (isClassCreated || hasCreatedClass)) {
      return false;
    }
    return true;
  }

  /// Stream all classes for a school (real-time)
  Stream<List<SchoolClass>> getClassesForSchool(String schoolCode) {
    return _db
      .collection('school_classes')
      .doc(schoolCode)
      .collection('classesData')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => SchoolClass.fromMap(doc.data())).toList());
  }

  /// Stream all classes assigned to a teacher (real-time, by UID or name)
  Stream<List<SchoolClass>> getClassesForTeacher(String schoolCode, String teacherUid, {String? teacherName}) {
    final createdByStream = _db
      .collection('school_classes')
      .doc(schoolCode)
      .collection('classesData')
      .where('createdBy', isEqualTo: teacherUid)
      .snapshots();

    final subjectTeacherStream = _db
      .collection('school_classes')
      .doc(schoolCode)
      .collection('classesData')
      .where('subjectTeachers', isGreaterThanOrEqualTo: null) // hack to get all
      .snapshots()
      .map((snap) => snap.docs.where((doc) {
        final map = doc.data() as Map<String, dynamic>;
        final subTeachers = map['subjectTeachers'] as Map<String, dynamic>?;
        if (subTeachers == null) return false;
        return teacherName != null && subTeachers.values.contains(teacherName);
      }).map((doc) => SchoolClass.fromMap(doc.data() as Map<String, dynamic>)).toList());

    return Rx.combineLatest2(
      createdByStream,
      subjectTeacherStream,
      (QuerySnapshot mainSnap, List<SchoolClass> subjectClasses) {
        final allDocs = <String, SchoolClass>{};
        for (final doc in mainSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          allDocs[doc.id] = SchoolClass.fromMap(data);
        }
        for (final c in subjectClasses) {
          allDocs['${c.className}_${c.section}'] = c;
        }
        return allDocs.values.toList();
      },
    );
  }

  /// Stream student count for a class-section (real-time)
  Stream<int> getStudentCountForClass(String schoolCode, String classId) {
    return _db
      .collection('student_master')
      .doc(schoolCode)
      .collection(classId)
      .doc('students')
      .snapshots()
      .map((docSnap) {
        final data = docSnap.data();
        if (data == null || data['students'] == null) return 0;
        return (data['students'] as List).length;
      });
  }

  /// Stream total student count for a school (real-time, web compatible)
  Stream<int> getTotalStudentCountForSchool(String schoolCode) {
    return getClassesForSchool(schoolCode).switchMap((classes) {
      if (classes.isEmpty) return Stream.value(0);
      // For each class, stream its student count and sum them
      final streams = classes.map((c) => getStudentCountForClass(schoolCode, '${c.className}_${c.section}'));
      return Rx.combineLatestList<int>(streams).map((counts) => counts.fold(0, (a, b) => a + b));
    });
  }

  /// Stream all marks for a class and exam (real-time)
  Stream<List<Map<String, dynamic>>> getMarksForClassExam(String schoolCode, String classId, String exam) {
    return _db
      .collection('marks')
      .doc(schoolCode)
      .collection(classId)
      .doc(exam)
      .collection('students')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Get marks for a single student for a class and exam
  Future<Map<String, dynamic>?> getStudentMarks(String schoolCode, String classId, String exam, String rollNumber) async {
    final doc = await _db
      .collection('marks')
      .doc(schoolCode)
      .collection(classId)
      .doc(exam)
      .collection('students')
      .doc(rollNumber)
      .get();
    return doc.exists ? doc.data() : null;
  }

  /// Upload or update marks for a student
  Future<void> uploadStudentMarks(String schoolCode, String classId, String exam, String rollNumber, Map<String, dynamic> marksData) async {
    await _db
      .collection('marks')
      .doc(schoolCode)
      .collection(classId)
      .doc(exam)
      .collection('students')
      .doc(rollNumber)
      .set(marksData, SetOptions(merge: true));
  }
}
