import 'excuse.dart';

abstract class ExcuseRepository {
  Future<void> submitExcuse(Excuse excuse);
  Future<Excuse?> getExcuse(String excuseId);
  Future<Excuse?> getExcuseByNonce(String tokenNonce);
  Future<int> countAcceptedExcusesInMonth(String uid, String monthKey);
  Stream<Excuse?> watchExcuse(String excuseId);
  Stream<List<Excuse>> watchExcusesForDate(String uid, String date);
  Future<void> updateExcuseStatus(String excuseId, String status);
}
