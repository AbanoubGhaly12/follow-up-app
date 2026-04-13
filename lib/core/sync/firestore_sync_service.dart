import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreSyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ─── User Operations ───

  Future<void> pushUser(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(data['uid']).set(data);
    } catch (e) {
      // Silently fail
    }
  }

  Future<List<Map<String, dynamic>>> getManagedUsers() async {
    if (currentUserId == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('parent_admin_uid', isEqualTo: currentUserId)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'uid': doc.id}).toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Zone Operations ───

  Future<void> pushZone(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    try {
      // Don't overwrite admin_uid if it already exists
      data['admin_uid'] ??= currentUserId;
      await _firestore.collection('zones').doc(data['id']).set(data);
    } catch (e) {
      // Silently fail – local data is the source of truth
    }
  }

  Future<void> deleteZoneRemote(String id) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('zones').doc(id).delete();
    } catch (e) {
      // Silently fail
    }
  }

  Future<bool> doesZoneTagExist(String tag) async {
    try {
      final snapshot = await _firestore
          .collection('zones')
          .where('tag', isEqualTo: tag)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchZones({bool isAdmin =false , bool fetchOther = false}) async {
    if (currentUserId == null) return [];
    try {
      if (isAdmin && fetchOther) {
        final snapshot = await _firestore.collection('zones').get();
        return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
      }
      // Get zones where user is primary admin
      final adminSnapshot = await _firestore
          .collection('zones')
          .where('admin_uid', isEqualTo: currentUserId)
          .get();

      // Get zones where user is sub-admin
      final subAdminSnapshot = await _firestore
          .collection('zones')
          .where('zone_admins', arrayContains: currentUserId)
          .get();

      final allDocs = [...adminSnapshot.docs, ...subAdminSnapshot.docs];
      final seenIds = <String>{};
      final results = <Map<String, dynamic>>[];

      for (var doc in allDocs) {
        if (seenIds.add(doc.id)) {
          results.add({...doc.data(), 'id': doc.id});
        }
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  // ─── Street Operations ───

  Future<void> pushStreet(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    try {
      await _firestore
          .collection('zones')
          .doc(data['zone_id'])
          .collection('streets')
          .doc(data['id'])
          .set(data);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> deleteStreetRemote(String id, String zoneId) async {
    if (currentUserId == null) return;
    try {
      await _firestore
          .collection('zones')
          .doc(zoneId)
          .collection('streets')
          .doc(id)
          .delete();
    } catch (e) {
      // Silently fail
    }
  }

  Future<List<Map<String, dynamic>>> fetchStreets(String zoneId) async {
    try {
      final snapshot = await _firestore
          .collection('zones')
          .doc(zoneId)
          .collection('streets')
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> doesStreetTagExist(String tag, String zoneId) async {
    try {
      final snapshot = await _firestore
          .collection('zones')
          .doc(zoneId)
          .collection('streets')
          .where('tag', isEqualTo: tag)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ─── Family Operations ───

  Future<bool> doesFamilyTagExist(String tag, String zoneId, String streetId) async {
    try {
      final snapshot = await _firestore
          .collection('zones')
          .doc(zoneId)
          .collection('streets')
          .doc(streetId)
          .collection('families')
          .where('tag', isEqualTo: tag)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> pushFamily(Map<String, dynamic> data, String zoneId) async {
    if (currentUserId == null) return;
    try {
      await _firestore
          .collection('zones')
          .doc(zoneId)
          .collection('streets')
          .doc(data['street_id'])
          .collection('families')
          .doc(data['id'])
          .set(data);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> deleteFamilyRemote(
    String id,
    String streetId,
    String zoneId,
  ) async {
    if (currentUserId == null) return;
    try {
      await _firestore
          .collection('zones')
          .doc(zoneId)
          .collection('streets')
          .doc(streetId)
          .collection('families')
          .doc(id)
          .delete();
    } catch (e) {
      // Silently fail
    }
  }

  Future<List<Map<String, dynamic>>> fetchFamilies(
    String zoneId,
    String streetId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('zones')
          .doc(zoneId)
          .collection('streets')
          .doc(streetId)
          .collection('families')
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Member Operations ───

  Future<bool> doesMemberTagExist(String tag, String zoneId, String streetId, String familyId) async {
    try {
      final snapshot = await _firestore
          .collection('zones')
          .doc(zoneId)
          .collection('streets')
          .doc(streetId)
          .collection('families')
          .doc(familyId)
          .collection('members')
          .where('tag', isEqualTo: tag)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> pushMember(
    Map<String, dynamic> data,
    String streetId,
    String zoneId,
  ) async {
    if (currentUserId == null) return;
    try {
      await _firestore
          .collection('zones')
          .doc(zoneId)
          .collection('streets')
          .doc(streetId)
          .collection('families')
          .doc(data['family_id'])
          .collection('members')
          .doc(data['id'])
          .set(data);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> deleteMemberRemote(
    String id,
    String familyId,
    String streetId,
    String zoneId,
  ) async {
    if (currentUserId == null) return;
    try {
      await _firestore
          .collection('zones')
          .doc(zoneId)
          .collection('streets')
          .doc(streetId)
          .collection('families')
          .doc(familyId)
          .collection('members')
          .doc(id)
          .delete();
    } catch (e) {
      // Silently fail
    }
  }

  Future<List<Map<String, dynamic>>> fetchMembers(
    String zoneId,
    String streetId,
    String familyId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('zones')
          .doc(zoneId)
          .collection('streets')
          .doc(streetId)
          .collection('families')
          .doc(familyId)
          .collection('members')
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Followup Operations ───

  Future<void> pushFollowup(Map<String, dynamic> data) async {
    if (currentUserId == null) return;
    try {
      data['user_uid'] = currentUserId;
      await _firestore.collection('followups').doc(data['id']).set(data);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> deleteFollowupRemote(String id) async {
    if (currentUserId == null) return;
    try {
      await _firestore.collection('followups').doc(id).delete();
    } catch (e) {
      // Silently fail
    }
  }

  Future<List<Map<String, dynamic>>> fetchFollowups() async {
    if (currentUserId == null) return [];
    try {
      final snapshot = await _firestore
          .collection('followups')
          .where('user_uid', isEqualTo: currentUserId)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      return [];
    }
  }

  // ─── User Profile ───

  Future<void> ensureUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'name': user.displayName ?? user.email?.split('@').first ?? '',
          'email': user.email ?? '',
          'created_at': FieldValue.serverTimestamp(),
          'role': 'subAdmin', // Default for now, as SuperAdmin is set manually
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<Map<String, dynamic>?> fetchUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return {...doc.data()!, 'uid': doc.id};
      }
    } catch (e) {
      // Error
    }
    return null;
  }
}
