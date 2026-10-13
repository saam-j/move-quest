import 'dart:math';

import '../models/movement_mode.dart';

enum MissionStatus { ready, playing, won, lost }

enum ForestItemType { energy, thorn }

class ForestItem {
  ForestItem({
    required this.id,
    required this.lane,
    required this.type,
    required this.y,
  });

  final int id;
  final int lane;
  final ForestItemType type;
  double y;
}

class RestoreWildTuning {
  const RestoreWildTuning({
    required this.itemSpeed,
    required this.spawnInterval,
    required this.reachWindow,
  });

  final double itemSpeed;
  final double spawnInterval;
  final double reachWindow;

  factory RestoreWildTuning.forMode(MovementMode mode) {
    final itemSpeed = switch (mode) {
      MovementMode.seated => 0.12,
      MovementMode.gentle => 0.15,
      MovementMode.active => 0.18,
    };
    final travelSpacing = 0.31;
    return RestoreWildTuning(
      itemSpeed: itemSpeed,
      spawnInterval: travelSpacing / itemSpeed,
      reachWindow: itemSpeed * 1.2,
    );
  }
}

class RestoreWildEngine {
  RestoreWildEngine(
    this.mode, {
    this.missionDuration = 90,
    Random? random,
  }) : _random = random ?? Random(2741);

  static const int objective = 6;
  static const int startingLives = 3;

  final MovementMode mode;
  final double missionDuration;
  final Random _random;
  final List<ForestItem> _items = [];

  MissionStatus status = MissionStatus.ready;
  double elapsed = 0;
  int lane = 1;
  int energyCollected = 0;
  int lives = startingLives;
  double _spawnElapsed = 0;
  int _nextItemId = 0;

  RestoreWildTuning get tuning => RestoreWildTuning.forMode(mode);
  int get score => energyCollected * 100;
  List<ForestItem> get items => List.unmodifiable(_items);

  void start() {
    status = MissionStatus.playing;
    elapsed = 0;
    lane = 1;
    energyCollected = 0;
    lives = startingLives;
    _spawnElapsed = 0;
    _nextItemId = 0;
    _items
      ..clear()
      ..add(
        ForestItem(
          id: _nextItemId++,
          lane: 1,
          type: ForestItemType.energy,
          y: 0.58,
        ),
      );
  }

  void movePlayer(int direction) {
    if (status != MissionStatus.playing || direction == 0) return;
    lane = (lane + direction.sign).clamp(0, 2).toInt();
  }

  bool reach() {
    if (status != MissionStatus.playing) return false;

    final catchDistance = tuning.reachWindow;
    ForestItem? target;
    for (final item in _items) {
      if (item.type == ForestItemType.energy &&
          item.lane == lane &&
          (item.y - 0.82).abs() <= catchDistance) {
        target = item;
        break;
      }
    }
    if (target == null) return false;

    _items.remove(target);
    energyCollected++;
    if (energyCollected >= objective) status = MissionStatus.won;
    return true;
  }

  void advance(double seconds) {
    if (status != MissionStatus.playing || seconds <= 0) return;

    elapsed += seconds;
    _spawnElapsed += seconds;
    while (_spawnElapsed >= tuning.spawnInterval) {
      _spawnElapsed -= tuning.spawnInterval;
      _spawnItem();
    }

    final crossedItems = <ForestItem>[];
    for (final item in _items) {
      final previousY = item.y;
      item.y += tuning.itemSpeed * seconds;
      if (item.type == ForestItemType.thorn &&
          item.lane == lane &&
          previousY < 0.82 &&
          item.y >= 0.82) {
        lives--;
        crossedItems.add(item);
        if (lives <= 0) {
          status = MissionStatus.lost;
          break;
        }
      } else if (item.y > 1.02) {
        crossedItems.add(item);
      }
    }
    _items.removeWhere(crossedItems.contains);

    if (status == MissionStatus.playing && elapsed >= missionDuration) {
      status = MissionStatus.lost;
    }
  }

  void _spawnItem() {
    final lane = _random.nextInt(3);
    final type = _random.nextDouble() < 0.27
        ? ForestItemType.thorn
        : ForestItemType.energy;
    _items.add(
      ForestItem(
        id: _nextItemId++,
        lane: lane,
        type: type,
        y: 0,
      ),
    );
  }
}
