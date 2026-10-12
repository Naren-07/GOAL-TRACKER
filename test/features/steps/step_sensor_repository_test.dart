import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/steps/domain/step_sensor_repository.dart';
import 'package:growthstreak/features/steps/data/mock_step_sensor_repository.dart';

void main() {
  group('StepSensorRepository Seam', () {
    late StepSensorRepository repository;

    setUp(() {
      repository = MockStepSensorRepository();
    });

    test('initial permission is false until requested or granted', () async {
      expect(await repository.checkPermission(), isFalse);
    });

    test('requestPermission grants activity recognition permission', () async {
      final granted = await repository.requestPermission();
      expect(granted, isTrue);
      expect(await repository.checkPermission(), isTrue);
    });

    test('rawStepCountStream emits incoming hardware steps', () async {
      final mock = repository as MockStepSensorRepository;

      expectLater(
        repository.rawStepCountStream,
        emitsInOrder([1000, 2500, 8100]),
      );

      mock.emitSteps(1000);
      mock.emitSteps(2500);
      mock.emitSteps(8100);
    });
  });
}
