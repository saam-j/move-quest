import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../gameplay/restore_wild_engine.dart';
import '../models/movement_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/adventure_backdrop.dart';
import '../widgets/restore_wild_arena.dart';
import '../widgets/tv_action_button.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key, required this.mode, this.engine});

  final MovementMode mode;
  final RestoreWildEngine? engine;

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  static const _tick = Duration(milliseconds: 50);

  late final RestoreWildEngine _engine;
  final FocusNode _gameFocusNode = FocusNode(debugLabel: 'Forest adventure');
  final FocusNode _playAgainFocusNode = FocusNode(debugLabel: 'Play again');
  final FocusNode _returnHomeFocusNode = FocusNode(debugLabel: 'Return home');
  Timer? _gameTimer;
  int _focusedResultAction = 0;

  @override
  void initState() {
    super.initState();
    _engine = widget.engine ?? RestoreWildEngine(widget.mode);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _gameFocusNode.dispose();
    _playAgainFocusNode.dispose();
    _returnHomeFocusNode.dispose();
    super.dispose();
  }

  void _startMission() {
    _engine.start();
    setState(() {});
    _gameFocusNode.requestFocus();
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(_tick, (_) {
      if (!mounted) return;
      setState(() {
        _engine.advance(_tick.inMilliseconds / 1000);
        if (_engine.status != MissionStatus.playing) {
          _gameTimer?.cancel();
          _gameTimer = null;
        }
      });
    });
  }

  void _restartMission() {
    _startMission();
  }

  KeyEventResult _handleGameKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_engine.status != MissionStatus.playing) {
      if (_engine.status == MissionStatus.won ||
          _engine.status == MissionStatus.lost) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowLeft:
            _selectResultAction(0);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.arrowRight:
            _selectResultAction(1);
            return KeyEventResult.handled;
          case LogicalKeyboardKey.enter:
          case LogicalKeyboardKey.select:
          case LogicalKeyboardKey.space:
            if (_focusedResultAction == 0) {
              _restartMission();
            } else {
              _goHome();
            }
            return KeyEventResult.handled;
          default:
            return KeyEventResult.ignored;
        }
      }
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        setState(() => _engine.movePlayer(-1));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        setState(() => _engine.movePlayer(1));
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.space:
        setState(() {
          _engine.reach();
        });
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _selectResultAction(int index) {
    _focusedResultAction = index;
    (index == 0 ? _playAgainFocusNode : _returnHomeFocusNode).requestFocus();
  }

  void _goHome() {
    _gameTimer?.cancel();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final status = _engine.status;
    return Focus(
      focusNode: _gameFocusNode,
      onKeyEvent: (node, event) => _handleGameKey(event),
      child: Scaffold(
        body: AdventureBackdrop(
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              child: switch (status) {
                MissionStatus.ready => _buildBriefing(),
                MissionStatus.playing => _buildGame(),
                MissionStatus.won || MissionStatus.lost => _buildResults(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBriefing() {
    return LayoutBuilder(
      key: const ValueKey('mission-briefing'),
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;
        return Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 34 : 64,
                  vertical: compact ? 12 : 30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: compact ? 62 : 86,
                      height: compact ? 62 : 86,
                      decoration: BoxDecoration(
                        color: AppTheme.lime.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: AppTheme.lime.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(
                        Icons.forest_rounded,
                        color: AppTheme.lime,
                        size: compact ? 39 : 54,
                      ),
                    ),
                    SizedBox(height: compact ? 8 : 18),
                    Text(
                      'RESTORE THE WILD',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: compact ? 30 : 43,
                            color: AppTheme.textPrimary,
                            letterSpacing: compact ? 1.2 : 2,
                          ),
                    ),
                    SizedBox(height: compact ? 4 : 10),
                    Text(
                      'A little forest magic needs your help.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontSize: compact ? 15 : null),
                    ),
                    SizedBox(height: compact ? 12 : 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _BriefingCard(
                          icon: Icons.auto_awesome_rounded,
                          color: AppTheme.lime,
                          title: 'GATHER ENERGY',
                          detail: 'Collect 6 glowing sparks',
                          compact: compact,
                        ),
                        SizedBox(width: compact ? 12 : 22),
                        _BriefingCard(
                          icon: Icons.spa_rounded,
                          color: AppTheme.teal,
                          title: 'DODGE THORNS',
                          detail: 'Keep your 3 forest hearts',
                          compact: compact,
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 12 : 25),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 15 : 28,
                        vertical: compact ? 9 : 15,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xAA102A20),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Text(
                        '← / →  MOVE BETWEEN PATHS     •     ↑ / SELECT  REACH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: compact ? 12 : 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: compact ? 0.3 : 1,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 25),
                    Text(
                      '${widget.mode.label} MODE  •  90 SECONDS  •  6 ENERGY SPARKS',
                      style: TextStyle(
                        color: widget.mode.accent,
                        fontSize: compact ? 11 : 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: compact ? 0.8 : 1.5,
                      ),
                    ),
                    SizedBox(height: compact ? 11 : 22),
                    SizedBox(
                      width: compact ? 300 : 380,
                      height: compact ? 50 : 66,
                      child: TvActionButton(
                        label: 'BEGIN MISSION',
                        icon: Icons.arrow_forward_rounded,
                        primary: true,
                        autofocus: true,
                        onPressed: _startMission,
                      ),
                    ),
                    SizedBox(height: compact ? 2 : 10),
                    TextButton(
                      onPressed: _goHome,
                      child: const Text('BACK TO HOME'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGame() {
    return LayoutBuilder(
      key: const ValueKey('mission-game'),
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 70,
            vertical: compact ? 8 : 26,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHud(compact),
              SizedBox(height: compact ? 7 : 14),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: RestoreWildArena(
                    key: const ValueKey('restore-wild-arena'),
                    engine: _engine,
                    modeAccent: widget.mode.accent,
                  ),
                ),
              ),
              SizedBox(height: compact ? 6 : 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: compact ? 18 : 24,
                    color: AppTheme.teal,
                  ),
                  SizedBox(width: compact ? 7 : 12),
                  Text(
                    'LEFT / RIGHT  MOVE',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: compact ? 11 : 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: compact ? 0.7 : 1.3,
                    ),
                  ),
                  SizedBox(width: compact ? 12 : 28),
                  Icon(
                    Icons.front_hand_rounded,
                    size: compact ? 17 : 22,
                    color: AppTheme.lime,
                  ),
                  SizedBox(width: compact ? 6 : 10),
                  Text(
                    'UP / SELECT  REACH',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: compact ? 11 : 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: compact ? 0.5 : 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHud(bool compact) {
    final remaining = (_engine.missionDuration - _engine.elapsed).ceil().clamp(
      0,
      999,
    );
    return Row(
      children: [
        Icon(
          Icons.forest_rounded,
          color: AppTheme.lime,
          size: compact ? 25 : 32,
        ),
        SizedBox(width: compact ? 8 : 12),
        Text(
          'RESTORE THE WILD',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: compact ? 16 : 24,
            fontWeight: FontWeight.w900,
            letterSpacing: compact ? 0.8 : 1.5,
          ),
        ),
        const Spacer(),
        _HudChip(
          icon: Icons.auto_awesome_rounded,
          color: AppTheme.lime,
          text: '${_engine.energyCollected} / ${RestoreWildEngine.objective}',
          compact: compact,
        ),
        SizedBox(width: compact ? 8 : 16),
        Row(
          children: List.generate(
            RestoreWildEngine.startingLives,
            (index) => Padding(
              padding: EdgeInsets.only(right: compact ? 2 : 5),
              child: Icon(
                Icons.favorite_rounded,
                color: index < _engine.lives
                    ? const Color(0xFFFF8A83)
                    : AppTheme.outline,
                size: compact ? 18 : 26,
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? 8 : 16),
        _HudChip(
          icon: Icons.hourglass_bottom_rounded,
          color: AppTheme.teal,
          text: '${remaining}s',
          compact: compact,
        ),
      ],
    );
  }

  Widget _buildResults() {
    final won = _engine.status == MissionStatus.won;
    return LayoutBuilder(
      key: const ValueKey('mission-results'),
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;
        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 28 : 50,
                vertical: compact ? 10 : 28,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      won ? Icons.park_rounded : Icons.eco_rounded,
                      size: compact ? 56 : 82,
                      color: won ? AppTheme.lime : AppTheme.teal,
                    ),
                    SizedBox(height: compact ? 4 : 14),
                    Text(
                      won ? 'THE WILD IS RESTORED!' : 'THE FOREST NEEDS YOU',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: compact ? 29 : 43,
                            color: won ? AppTheme.lime : AppTheme.textPrimary,
                            letterSpacing: compact ? 0.4 : 1.4,
                          ),
                    ),
                    SizedBox(height: compact ? 4 : 10),
                    Text(
                      won
                          ? 'Every spark brought the forest back to life.'
                          : _engine.lives == 0
                          ? 'The thorny vines caught you. Take a breath and try again.'
                          : 'Time ran out. The forest is ready when you are.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontSize: compact ? 14 : null),
                    ),
                    SizedBox(height: compact ? 10 : 22),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 25 : 50,
                        vertical: compact ? 11 : 22,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xD9112B21),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: (won ? AppTheme.lime : AppTheme.teal)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ResultStat(
                            label: 'ENERGY',
                            value:
                                '${_engine.energyCollected} / ${RestoreWildEngine.objective}',
                            compact: compact,
                          ),
                          SizedBox(width: compact ? 28 : 56),
                          _ResultStat(
                            label: 'SCORE',
                            value: '${_engine.score}',
                            compact: compact,
                          ),
                          SizedBox(width: compact ? 28 : 56),
                          _ResultStat(
                            label: 'TIME',
                            value: '${_engine.elapsed.floor()}s',
                            compact: compact,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: compact ? 7 : 14),
                    Text(
                      '${widget.mode.label} MODE SCORE · SCORES ARE NOT A MEASURE OF PHYSICAL EFFORT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: compact ? 8 : 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: compact ? 0.1 : 0.6,
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: compact ? 10 : 18,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: compact ? 260 : 330,
                          height: compact ? 48 : 60,
                          child: TvActionButton(
                            label: 'PLAY AGAIN',
                            icon: Icons.replay_rounded,
                            focusNode: _playAgainFocusNode,
                            primary: true,
                            autofocus: true,
                            onPressed: _restartMission,
                          ),
                        ),
                        SizedBox(
                          width: compact ? 260 : 330,
                          height: compact ? 48 : 60,
                          child: TvActionButton(
                            label: 'RETURN HOME',
                            icon: Icons.home_rounded,
                            focusNode: _returnHomeFocusNode,
                            onPressed: _goHome,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BriefingCard extends StatelessWidget {
  const _BriefingCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 24,
          vertical: compact ? 10 : 18,
        ),
        decoration: BoxDecoration(
          color: const Color(0xAA112B21),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: compact ? 24 : 34, color: color),
            SizedBox(width: compact ? 8 : 15),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: compact ? 10 : 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: compact ? 0.2 : 0.8,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 5),
                  Text(
                    detail,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: compact ? 10 : 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudChip extends StatelessWidget {
  const _HudChip({
    required this.icon,
    required this.color,
    required this.text,
    required this.compact,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 16,
        vertical: compact ? 5 : 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xAA112B21),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: compact ? 16 : 22),
          SizedBox(width: compact ? 4 : 8),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: compact ? 13 : 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: compact ? 9 : 13,
            fontWeight: FontWeight.w900,
            letterSpacing: compact ? 0.5 : 1,
          ),
        ),
        SizedBox(height: compact ? 2 : 5),
        Text(
          value,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: compact ? 20 : 30,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
