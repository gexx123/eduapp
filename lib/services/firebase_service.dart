import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// Adds a user to the group_member collection after joining/creating a school.
  ///
  /// The document ID is set to the user's UID for Firestore rule compatibility.
  static Future<void> addToGroupMember({
    required String userId,
    required String name,
    required String role, // 'principal', 'teacher', 'parent'
    required String schoolCode,
    required String schoolName,
    String image = '',
  }) async {
    // Use UID as document ID (NOT random) for Firestore rules compatibility
    final groupMemberDoc = firestore.collection('group_member').doc(userId);
    await groupMemberDoc.set({
      'userId': userId,
      'name': name,
      'role': role,
      'schoolCode': schoolCode,
      'schoolName': schoolName,
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
      'image': image,
    }, SetOptions(merge: true));
  }

  /// Query group members by school code and optional role
  static Future<List<Map<String, dynamic>>> getGroupMembers({
    required String schoolCode,
    String? role,
  }) async {
    Query query = firestore.collection('group_member').where('schoolCode', isEqualTo: schoolCode);
    if (role != null) {
      query = query.where('role', isEqualTo: role);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  /// Returns the group_member docId for a user (if any)
  static Future<String?> getGroupMemberDocId(String userId) async {
    final query = await firestore.collection('group_member').where('userId', isEqualTo: userId).limit(1).get();
    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    }
    return null;
  }
}
