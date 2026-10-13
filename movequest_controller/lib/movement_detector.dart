enum Movement {
  none,
  leftArmRaise,
  rightArmRaise,
  bothArmsRaised,
  leanScreenLeft,
  leanScreenRight;

  String get label => switch (this) {
        Movement.none => 'No movement detected',
        Movement.leftArmRaise => 'Left arm raised',
        Movement.rightArmRaise => 'Right arm raised',
        Movement.bothArmsRaised => 'Both arms raised',
        Movement.leanScreenLeft => 'Lean screen-left · experimental',
        Movement.leanScreenRight => 'Lean screen-right · experimental',
      };

  bool get isShift =>
      this == Movement.leanScreenLeft || this == Movement.leanScreenRight;
}

class PosePoint {
  const PosePoint({
    required this.x,
    required this.y,
    required this.visibility,
    required this.presence,
  });

  final double x;
  final double y;
  final double visibility;
  final double presence;

  factory PosePoint.fromEvent(Map<Object?, Object?> event) => PosePoint(
        x: (event['x'] as num).toDouble(),
        y: (event['y'] as num).toDouble(),
        visibility: (event['visibility'] as num?)?.toDouble() ?? 0,
        presence: (event['presence'] as num?)?.toDouble() ?? 0,
      );
}

class MovementUpdate {
  const MovementUpdate(this.movement, this.events);

  final Movement movement;
  final List<Movement> events;
}

class MovementDetector {
  static const _enterRaise = 0.11;
  static const _exitRaise = 0.04;
  static const _enterLean = 0.22;
  static const _exitLean = 0.11;
  static const _requiredStableFrames = 3;
  static const _requiredLeanFrames = 5;
  static const _minimumConfidence = 0.35;

  double? _leftRaiseAmount;
  double? _rightRaiseAmount;
  double? _leanAmount;
  bool _leftRaised = false;
  bool _rightRaised = false;
  Movement _stableMovement = Movement.none;
  Movement _candidateMovement = Movement.none;
  int _candidateFrames = 0;

  MovementUpdate update(
    List<PosePoint> landmarks, {
    required bool mirrored,
  }) {
    if (landmarks.length < 29 || !_hasUsableTorso(landmarks)) {
      reset();
      return const MovementUpdate(Movement.none, []);
    }

    final leftAmount = landmarks[11].y - landmarks[15].y;
    final rightAmount = landmarks[12].y - landmarks[16].y;
    _leftRaiseAmount = _smooth(_leftRaiseAmount, leftAmount);
    _rightRaiseAmount = _smooth(_rightRaiseAmount, rightAmount);
    _leftRaised = _nextHysteresis(
      _leftRaised,
      _leftRaiseAmount!,
      _enterRaise,
      _exitRaise,
    );
    _rightRaised = _nextHysteresis(
      _rightRaised,
      _rightRaiseAmount!,
      _enterRaise,
      _exitRaise,
    );

    final shouldersCenter = (landmarks[11].x + landmarks[12].x) / 2;
    final hipsCenter = (landmarks[23].x + landmarks[24].x) / 2;
    final shoulderWidth = (landmarks[11].x - landmarks[12].x).abs();
    final lean = shoulderWidth < 0.05
        ? 0.0
        : (hipsCenter - shouldersCenter) / shoulderWidth;
    _leanAmount = _smooth(_leanAmount, mirrored ? -lean : lean);

    final movement = _selectMovement();
    final requiredFrames = movement.isShift
        ? _requiredLeanFrames
        : _requiredStableFrames;
    if (movement == _candidateMovement) {
      _candidateFrames++;
    } else {
      _candidateMovement = movement;
      _candidateFrames = 1;
    }

    if (_candidateFrames < requiredFrames || movement == _stableMovement) {
      return MovementUpdate(_stableMovement, const []);
    }

    _stableMovement = movement;
    return MovementUpdate(
      movement,
      movement == Movement.none ? const [] : [movement],
    );
  }

  Movement _selectMovement() {
    if (_leftRaised && _rightRaised) return Movement.bothArmsRaised;
    if (_leftRaised) return Movement.leftArmRaise;
    if (_rightRaised) return Movement.rightArmRaise;

    final lean = _leanAmount ?? 0;
    if (lean > _enterLean ||
        (_stableMovement == Movement.leanScreenRight && lean > _exitLean)) {
      return Movement.leanScreenRight;
    }
    if (lean < -_enterLean ||
        (_stableMovement == Movement.leanScreenLeft && lean < -_exitLean)) {
      return Movement.leanScreenLeft;
    }
    return Movement.none;
  }

  bool _hasUsableTorso(List<PosePoint> points) {
    const required = [11, 12, 13, 14, 15, 16, 23, 24];
    return required.every(
      (index) =>
          points[index].visibility >= _minimumConfidence ||
          points[index].presence >= _minimumConfidence,
    );
  }

  bool _nextHysteresis(bool active, double value, double enter, double exit) =>
      active ? value > exit : value > enter;

  double _smooth(double? previous, double value) =>
      previous == null ? value : previous + 0.35 * (value - previous);

  void reset() {
    _leftRaiseAmount = null;
    _rightRaiseAmount = null;
    _leanAmount = null;
    _leftRaised = false;
    _rightRaised = false;
    _stableMovement = Movement.none;
    _candidateMovement = Movement.none;
    _candidateFrames = 0;
  }
}
