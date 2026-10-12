import 'dart:async';
import '../domain/step_sensor_repository.dart';

class MockStepSensorRepository implements StepSensorRepository {
  bool _isPermissionGranted;
  final StreamController<int> _stepController =
      StreamController<int>.broadcast();

  MockStepSensorRepository({bool initialPermissionGranted = false})
      : _isPermissionGranted = initialPermissionGranted;

  @override
  Stream<int> get rawStepCountStream => _stepController.stream;

  @override
  Future<bool> checkPermission() async {
    return _isPermissionGranted;
  }

  @override
  Future<bool> requestPermission() async {
    _isPermissionGranted = true;
    return true;
  }

  void emitSteps(int steps) {
    _stepController.add(steps);
  }

  void dispose() {
    _stepController.close();
  }
}
