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
  final int _millisecond;

  SleepPolicyTimer(
    this.duration,
    this._millisecond,
  );

  @override
  bool operator ==(Object other) {
    return other is SleepPolicyTimer &&
        other.duration == duration &&
        other._millisecond == _millisecond;
  }

  @override
  String toString() {
    return 'SleepPolicyTimer($duration, $_millisecond)';
  }
}

SleepPolicy sleepPolicyNotSet() => SleepPolicyNotSet();

SleepPolicy sleepPolicyOff() => SleepPolicyOff();

SleepPolicy sleepPolicyMinutes(int minutes) => SleepPolicyTimer(
      Duration(minutes: minutes),
      DateTime.now().millisecondsSinceEpoch,
    );
