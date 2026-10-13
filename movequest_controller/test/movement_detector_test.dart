import 'package:flutter_test/flutter_test.dart';
import 'package:movequest_controller/movement_detector.dart';

void main() {
  test('recognizes a left-arm raise once after temporal smoothing', () {
    final detector = MovementDetector();
    final pose = _pose(leftWristY: 0.2);
    final updates = List.generate(
      12,
      (_) => detector.update(pose, mirrored: false),
    );
    final events = updates.expand((update) => update.events).toList();

    expect(events, [Movement.leftArmRaise]);
    expect(updates.last.movement, Movement.leftArmRaise);
  });

  test('recognizes both raised arms as one gesture', () {
    final detector = MovementDetector();
    final pose = _pose(leftWristY: 0.2, rightWristY: 0.2);
    final updates = List.generate(
      12,
      (_) => detector.update(pose, mirrored: false),
    );

    expect(updates.expand((update) => update.events), [
      Movement.bothArmsRaised,
    ]);
  });

  test('recognizes a right-arm raise independently', () {
    final detector = MovementDetector();
    final pose = _pose(rightWristY: 0.2);
    final updates = List.generate(
      12,
      (_) => detector.update(pose, mirrored: false),
    );

    expect(updates.expand((update) => update.events), [Movement.rightArmRaise]);
  });

  test('labels horizontal hip offset as an experimental screen shift', () {
    final detector = MovementDetector();
    final pose = _pose(hipCenterX: 0.57);
    final updates = List.generate(
      16,
      (_) => detector.update(pose, mirrored: false),
    );

    expect(updates.last.movement, Movement.leanScreenRight);
    expect(updates.expand((update) => update.events), [
      Movement.leanScreenRight,
    ]);
  });

  test('requires a stable lowered pose before the same raise counts again', () {
    final detector = MovementDetector();
    final raised = _pose(leftWristY: 0.2);
    final lowered = _pose(leftWristY: 0.55);
    final events = <Movement>[];
    for (var i = 0; i < 12; i++) {
      events.addAll(detector.update(raised, mirrored: false).events);
    }
    for (var i = 0; i < 12; i++) {
      events.addAll(detector.update(lowered, mirrored: false).events);
    }
    for (var i = 0; i < 12; i++) {
      events.addAll(detector.update(raised, mirrored: false).events);
    }

    expect(events, [Movement.leftArmRaise, Movement.leftArmRaise]);
  });
}

List<PosePoint> _pose({
  double leftWristY = 0.55,
  double rightWristY = 0.55,
  double hipCenterX = 0.5,
}) {
  final points = List.generate(
    33,
    (_) => const PosePoint(x: 0.5, y: 0.5, visibility: 0.9, presence: 0.9),
  );
  points[11] = const PosePoint(x: 0.4, y: 0.4, visibility: 0.9, presence: 0.9);
  points[12] = const PosePoint(x: 0.6, y: 0.4, visibility: 0.9, presence: 0.9);
  points[13] = const PosePoint(x: 0.4, y: 0.48, visibility: 0.9, presence: 0.9);
  points[14] = const PosePoint(x: 0.6, y: 0.48, visibility: 0.9, presence: 0.9);
  points[15] = PosePoint(x: 0.4, y: leftWristY, visibility: 0.9, presence: 0.9);
  points[16] = PosePoint(
    x: 0.6,
    y: rightWristY,
    visibility: 0.9,
    presence: 0.9,
  );
  points[23] = PosePoint(
    x: hipCenterX - 0.05,
    y: 0.65,
    visibility: 0.9,
    presence: 0.9,
  );
  points[24] = PosePoint(
    x: hipCenterX + 0.05,
    y: 0.65,
    visibility: 0.9,
    presence: 0.9,
  );
  return points;
}
