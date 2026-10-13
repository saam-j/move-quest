import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:movequest_tv/gameplay/restore_wild_engine.dart';
import 'package:movequest_tv/models/movement_mode.dart';

class _CenterLaneRandom implements Random {
  _CenterLaneRandom({required this.thorns});

  final bool thorns;

  @override
  int nextInt(int max) => 1;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => thorns ? 0 : 0.99;
}

void main() {
  group('RestoreWildEngine', () {
    test('all modes keep the same goal and a fair reaction window', () {
      final tunings = MovementMode.values
          .map(RestoreWildTuning.forMode)
          .toList();

      expect(RestoreWildEngine.objective, 6);
      expect(
        tunings.map((tuning) => tuning.spawnInterval * tuning.itemSpeed),
        everyElement(closeTo(0.31, 0.0001)),
      );
      expect(
        tunings.map((tuning) => tuning.reachWindow / tuning.itemSpeed),
        everyElement(closeTo(1.2, 0.0001)),
      );
    });

    test('collecting six sparks wins and scores only collected energy', () {
      final engine = RestoreWildEngine(
        MovementMode.gentle,
        random: _CenterLaneRandom(thorns: false),
      )..start();

      for (
        var tick = 0;
        tick < 1800 && engine.status == MissionStatus.playing;
        tick++
      ) {
        engine.advance(0.05);
        engine.reach();
      }

      expect(engine.status, MissionStatus.won);
      expect(engine.energyCollected, RestoreWildEngine.objective);
      expect(engine.score, 600);
    });

    test('three thorn hits end the mission', () {
      final engine = RestoreWildEngine(
        MovementMode.seated,
        random: _CenterLaneRandom(thorns: true),
      )..start();

      for (
        var tick = 0;
        tick < 1800 && engine.status == MissionStatus.playing;
        tick++
      ) {
        engine.advance(0.05);
      }

      expect(engine.status, MissionStatus.lost);
      expect(engine.lives, 0);
    });

    test('the timer ends an unfinished mission', () {
      final engine = RestoreWildEngine(MovementMode.active, missionDuration: 1)
        ..start();

      for (
        var tick = 0;
        tick < 200 && engine.status == MissionStatus.playing;
        tick++
      ) {
        engine.advance(0.05);
      }

      expect(engine.status, MissionStatus.lost);
      expect(engine.energyCollected, 0);
    });
  });
}
