import 'package:flutter_test/flutter_test.dart';
import 'package:movequest_controller/main.dart';

void main() {
  test('rotates landscape landmarks clockwise for portrait preview', () {
    final frame = _frame(90);

    expect(frame.landmarks.single.x, closeTo(0.7, 1e-9));
    expect(frame.landmarks.single.y, closeTo(0.2, 1e-9));
  });

  test('rotates landscape landmarks counterclockwise for portrait preview', () {
    final frame = _frame(270);

    expect(frame.landmarks.single.x, closeTo(0.3, 1e-9));
    expect(frame.landmarks.single.y, closeTo(0.8, 1e-9));
  });
}

PoseFrame _frame(int rotationDegrees) => PoseFrame.fromEvent({
  'status': 'tracking',
  'rotationDegrees': rotationDegrees,
  'landmarks': [
    {'x': 0.2, 'y': 0.3, 'visibility': 0.8, 'presence': 0.9},
  ],
});
