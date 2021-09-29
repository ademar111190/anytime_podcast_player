abstract class SleepPolicy {
  bool feedbackGiven;

  SleepPolicy(
    this.feedbackGiven,
  );
}

class SleepPolicyOff extends SleepPolicy {
  SleepPolicyOff(
    bool feedbackGiven,
  ) : super(feedbackGiven);

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
    bool feedbackGiven,
  ) : super(feedbackGiven);

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

SleepPolicy sleepPolicyOff([bool feedbackGiven = false]) =>
    SleepPolicyOff(feedbackGiven);

SleepPolicy sleepPolicyMinutes(int minutes) => SleepPolicyTimer(
      Duration(minutes: minutes),
      DateTime.now().millisecondsSinceEpoch,
      false,
    );
