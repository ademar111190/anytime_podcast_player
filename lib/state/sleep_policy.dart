abstract class SleepPolicy {}

class SleepPolicyNotSet extends SleepPolicy {
  @override
  bool operator ==(Object other) {
    return other is SleepPolicyNotSet;
  }
}

class SleepPolicyOff extends SleepPolicy {
  @override
  bool operator ==(Object other) {
    return other is SleepPolicyOff;
  }
}

class SleepPolicyTimer extends SleepPolicy {
  final Duration duration;

  SleepPolicyTimer(
    this.duration,
  );

  @override
  bool operator ==(Object other) {
    return other is SleepPolicyTimer && other.duration == duration;
  }

  @override
  String toString() {
    return 'SleepPolicyTimer($duration)';
  }
}

SleepPolicy sleepPolicyNotSet() => SleepPolicyNotSet();

SleepPolicy sleepPolicyOff() => SleepPolicyOff();

SleepPolicy sleepPolicyMinutes(int minutes) => SleepPolicyTimer(
      Duration(minutes: minutes),
    );
