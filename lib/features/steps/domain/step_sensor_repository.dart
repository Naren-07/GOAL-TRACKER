abstract class StepSensorRepository {
  Stream<int> get rawStepCountStream;
  Future<bool> checkPermission();
  Future<bool> requestPermission();
}
