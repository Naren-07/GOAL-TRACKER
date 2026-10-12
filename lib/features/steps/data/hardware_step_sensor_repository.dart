import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/step_sensor_repository.dart';

class HardwareStepSensorRepository implements StepSensorRepository {
  @override
  Stream<int> get rawStepCountStream {
    return Pedometer.stepCountStream.map((event) => event.steps);
  }

  @override
  Future<bool> checkPermission() async {
    final status = await Permission.activityRecognition.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }
}
