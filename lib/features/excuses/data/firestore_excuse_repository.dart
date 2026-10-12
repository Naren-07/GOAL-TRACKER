import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/excuse.dart';
import '../domain/excuse_repository.dart';

class FirestoreExcuseRepository implements ExcuseRepository {
  final FirebaseFirestore _firestore;

  FirestoreExcuseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _excusesRef =>
      _firestore.collection('excuses');

  @override
  Future<void> submitExcuse(Excuse excuse) async {
    await _excusesRef.doc(excuse.id).set(excuse.toMap());
  }

  @override
  Future<Excuse?> getExcuse(String excuseId) async {
    final doc = await _excusesRef.doc(excuseId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Excuse.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<Excuse?> getExcuseByNonce(String tokenNonce) async {
    final query = await _excusesRef
        .where('tokenNonce', isEqualTo: tokenNonce)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return Excuse.fromMap(query.docs.first.data(), query.docs.first.id);
  }

  @override
  Future<int> countAcceptedExcusesInMonth(String uid, String monthKey) async {
    final query = await _excusesRef
        .where('uid', isEqualTo: uid)
        .where('monthKey', isEqualTo: monthKey)
        .where('status', isEqualTo: 'accepted')
        .get();
    return query.docs.length;
  }

  @override
  Stream<Excuse?> watchExcuse(String excuseId) {
    return _excusesRef.doc(excuseId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Excuse.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Stream<List<Excuse>> watchExcusesForDate(String uid, String date) {
    return _excusesRef
        .where('uid', isEqualTo: uid)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Excuse.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> updateExcuseStatus(String excuseId, String status) async {
    await _excusesRef.doc(excuseId).update({'status': status});
  }
}
