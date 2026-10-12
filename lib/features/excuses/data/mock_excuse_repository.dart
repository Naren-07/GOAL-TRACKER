import 'dart:async';
import '../domain/excuse.dart';
import '../domain/excuse_repository.dart';

class MockExcuseRepository implements ExcuseRepository {
  final Map<String, Excuse> _excuses = {};
  final _excuseStreamController =
      StreamController<Map<String, Excuse>>.broadcast();

  @override
  Future<void> submitExcuse(Excuse excuse) async {
    _excuses[excuse.id] = excuse;
    _excuseStreamController.add(Map.unmodifiable(_excuses));
  }

  @override
  Future<Excuse?> getExcuse(String excuseId) async {
    return _excuses[excuseId];
  }

  @override
  Future<Excuse?> getExcuseByNonce(String tokenNonce) async {
    try {
      return _excuses.values.firstWhere((e) => e.tokenNonce == tokenNonce);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> countAcceptedExcusesInMonth(String uid, String monthKey) async {
    return _excuses.values
        .where((e) =>
            e.uid == uid && e.monthKey == monthKey && e.status == 'accepted')
        .length;
  }

  @override
  Stream<Excuse?> watchExcuse(String excuseId) async* {
    yield _excuses[excuseId];
    yield* _excuseStreamController.stream.map((map) => map[excuseId]);
  }

  @override
  Stream<List<Excuse>> watchExcusesForDate(String uid, String date) async* {
    yield _excuses.values
        .where((e) => e.uid == uid && e.date == date)
        .toList();
    yield* _excuseStreamController.stream.map((map) => map.values
        .where((e) => e.uid == uid && e.date == date)
        .toList());
  }

  @override
  Future<void> updateExcuseStatus(String excuseId, String status) async {
    final existing = _excuses[excuseId];
    if (existing != null) {
      _excuses[excuseId] = existing.copyWith(status: status);
      _excuseStreamController.add(Map.unmodifiable(_excuses));
    }
  }

  void dispose() {
    _excuseStreamController.close();
  }
}
