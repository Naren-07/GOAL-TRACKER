import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/habit_task.dart';
import '../domain/task_repository.dart';

class FirestoreTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore;

  FirestoreTaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasksCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('tasks');

  @override
  Future<List<HabitTask>> fetchTasks(String uid) async {
    final snapshot = await _tasksCollection(uid).get();
    return snapshot.docs
        .map((doc) => HabitTask.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Stream<List<HabitTask>> watchTasks(String uid) {
    return _tasksCollection(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => HabitTask.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> saveTask(String uid, HabitTask task) async {
    await _tasksCollection(uid).doc(task.id).set(
          task.toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteTask(String uid, String taskId) async {
    await _tasksCollection(uid).doc(taskId).delete();
  }
}
