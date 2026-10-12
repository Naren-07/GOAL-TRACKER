class StepCalculationResult {
  final int todaySteps;
  final Map<String, int> updatedBaselines;

  const StepCalculationResult({
    required this.todaySteps,
    required this.updatedBaselines,
  });
}

class StepTrackerService {
  StepCalculationResult calculateSteps({
    required int rawSensorSteps,
    required String date,
    required Map<String, int> baselines,
  }) {
    final updated = Map<String, int>.from(baselines);
    final currentBaseline = updated[date];

    if (currentBaseline == null) {
      updated[date] = rawSensorSteps;
      return StepCalculationResult(
        todaySteps: 0,
        updatedBaselines: updated,
      );
    }

    if (rawSensorSteps < currentBaseline) {
      // Device was rebooted since baseline was established
      updated[date] = 0;
      return StepCalculationResult(
        todaySteps: rawSensorSteps,
        updatedBaselines: updated,
      );
    }

    final todaySteps = rawSensorSteps - currentBaseline;
    return StepCalculationResult(
      todaySteps: todaySteps,
      updatedBaselines: updated,
    );
  }
}
