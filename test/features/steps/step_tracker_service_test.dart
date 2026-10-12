import 'package:flutter_test/flutter_test.dart';
import 'package:growthstreak/features/steps/domain/step_tracker_service.dart';

void main() {
  group('StepTrackerService Seam', () {
    late StepTrackerService service;

    setUp(() {
      service = StepTrackerService();
    });

    test('initial reading on a date establishes the baseline and yields 0 steps', () {
      final baselines = <String, int>{};
      final result = service.calculateSteps(
        rawSensorSteps: 12000,
        date: '2026-10-12',
        baselines: baselines,
      );

      expect(result.todaySteps, 0);
      expect(result.updatedBaselines['2026-10-12'], 12000);
    });

    test('subsequent readings on the same date calculate delta from baseline', () {
      final baselines = {'2026-10-12': 12000};
      final result = service.calculateSteps(
        rawSensorSteps: 15500,
        date: '2026-10-12',
        baselines: baselines,
      );

      expect(result.todaySteps, 3500); // 15500 - 12000
      expect(result.updatedBaselines['2026-10-12'], 12000);
    });

    test('midnight date transition resets delta and establishes new day baseline', () {
      final baselines = {'2026-10-12': 12000};

      // Sensor reading reaches 20000 on 2026-10-12
      final day1Result = service.calculateSteps(
        rawSensorSteps: 20000,
        date: '2026-10-12',
        baselines: baselines,
      );
      expect(day1Result.todaySteps, 8000);

      // Now midnight rolls over to 2026-10-13, sensor is at 20050
      final day2Result = service.calculateSteps(
        rawSensorSteps: 20050,
        date: '2026-10-13',
        baselines: day1Result.updatedBaselines,
      );

      expect(day2Result.todaySteps, 0);
      expect(day2Result.updatedBaselines['2026-10-13'], 20050);
      expect(day2Result.updatedBaselines['2026-10-12'], 12000); // historical preserved
    });

    test('device reboot resets baseline cleanly without negative step counts', () {
      final baselines = {'2026-10-12': 15000};

      // Device reboots, sensor starts at 200
      final result = service.calculateSteps(
        rawSensorSteps: 200,
        date: '2026-10-12',
        baselines: baselines,
      );

      expect(result.todaySteps, 200);
      expect(result.updatedBaselines['2026-10-12'], 0);
    });
  });
}
