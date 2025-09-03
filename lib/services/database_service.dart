import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task.dart';
import '../models/subject.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Subjects
  Future<List<Subject>> getSubjects() async {
    final snapshot = await _firestore.collection('subjects').get();
    return snapshot.docs.map((doc) => Subject.fromJson(doc.data())).toList();
  }

  Future<void> addSubject(Subject subject) async {
    await _firestore.collection('subjects').doc(subject.id).set(subject.toJson());
  }

  Future<void> updateSubject(Subject subject) async {
    await _firestore.collection('subjects').doc(subject.id).update(subject.toJson());
  }

  Future<void> deleteSubject(String id) async {
    await _firestore.collection('subjects').doc(id).delete();
  }

  // Tasks
  Future<List<Task>> getTasks() async {
    final snapshot = await _firestore.collection('tasks').get();
    return snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList();
  }

  Future<void> addTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toJson());
  }

  Future<void> updateTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).update(task.toJson());
  }

  Future<void> deleteTask(String id) async {
    await _firestore.collection('tasks').doc(id).delete();
  }

  Stream<List<Task>> getTasksStream() {
    return _firestore.collection('tasks').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Task.fromJson(doc.data())).toList(),
    );
  }
}