import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/movement_mode.dart';
import '../theme/app_theme.dart';
import '../widgets/adventure_backdrop.dart';
import '../widgets/tv_action_button.dart';
import 'mission_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<FocusNode> _modeFocusNodes;
  final FocusNode _startFocusNode = FocusNode(debugLabel: 'Start adventure');
  final FocusNode _helpFocusNode = FocusNode(debugLabel: 'Settings and help');
  MovementMode _selectedMode = MovementMode.gentle;

  @override
  void initState() {
    super.initState();
    _modeFocusNodes = MovementMode.values
        .map((mode) => FocusNode(debugLabel: '${mode.label} mode'))
        .toList();
  }

  @override
  void dispose() {
    for (final focusNode in _modeFocusNodes) {
      focusNode.dispose();
    }
    _startFocusNode.dispose();
    _helpFocusNode.dispose();
    super.dispose();
  }

  void _selectMode(MovementMode mode) {
    if (_selectedMode == mode) return;
    setState(() => _selectedMode = mode);
  }

  KeyEventResult _handleModeKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _startFocusNode.requestFocus();
      return KeyEventResult.handled;
    }

    final nextIndex = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => index - 1,
      LogicalKeyboardKey.arrowRight => index + 1,
      _ => index,
    };
    if (nextIndex == index) return KeyEventResult.ignored;
    if (nextIndex < 0 || nextIndex >= _modeFocusNodes.length) {
      return KeyEventResult.handled;
    }
    _modeFocusNodes[nextIndex].requestFocus();
    _selectMode(MovementMode.values[nextIndex]);
    return KeyEventResult.handled;
  }

  KeyEventResult _handleStartKey(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final selectedIndex = MovementMode.values.indexOf(_selectedMode);
      _modeFocusNodes[selectedIndex].requestFocus();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _helpFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleHelpKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _startFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _startAdventure() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MissionScreen(mode: _selectedMode),
      ),
    );
  }

  Future<void> _showHelp() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Settings & help'),
        content: const Text(
          'Choose the movement style that feels right for your family. '
          'Use the left and right buttons on your remote to select a mode, '
          'then press Select to begin.',
        ),
        actions: [
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdventureBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;
              final horizontalPadding = constraints.maxWidth < 1000
                  ? 38.0
                  : (compact ? 56.0 : 86.0);
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1640),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: compact ? 10 : 30,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(compact),
                            SizedBox(height: compact ? 14 : 38),
                            _buildWelcome(compact),
                            SizedBox(height: compact ? 15 : 38),
                            _buildModePicker(compact),
                            SizedBox(height: compact ? 16 : 34),
                            _buildStartButton(compact),
                            SizedBox(height: compact ? 12 : 28),
                            _buildFooter(compact),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool compact) {
    return Row(
      children: [
        Container(
          width: compact ? 42 : 58,
          height: compact ? 42 : 58,
          decoration: BoxDecoration(
            color: AppTheme.lime,
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: AppTheme.lime.withValues(alpha: 0.2),
                blurRadius: 22,
              ),
            ],
          ),
          child: Icon(
            Icons.explore_rounded,
            color: AppTheme.background,
            size: compact ? 26 : 36,
          ),
        ),
        SizedBox(width: compact ? 11 : 17),
        Text(
          'MOVEQUEST',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: compact ? 22 : 29,
            fontWeight: FontWeight.w900,
            letterSpacing: compact ? 1.8 : 2.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 11 : 17,
            vertical: compact ? 7 : 11,
          ),
          decoration: BoxDecoration(
            color: const Color(0x331A3A2B),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.outline),
          ),
          child: Row(
            children: [
              Icon(
                Icons.groups_rounded,
                color: AppTheme.teal,
                size: compact ? 16 : 21,
              ),
              SizedBox(width: compact ? 6 : 9),
              Text(
                'A FAMILY FITNESS ADVENTURE',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: compact ? 10 : 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: compact ? 0.8 : 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcome(bool compact) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: AppTheme.lime,
                    size: compact ? 15 : 21,
                  ),
                  SizedBox(width: compact ? 7 : 10),
                  Text(
                    'YOUR FAMILY’S NEXT QUEST',
                    style: TextStyle(
                      color: AppTheme.lime,
                      fontSize: compact ? 12 : 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: compact ? 1.35 : 2.1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 7 : 17),
              Text(
                'Play. Move. Progress.',
                maxLines: 1,
                softWrap: false,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: compact ? 43 : 60,
                ),
              ),
              SizedBox(height: compact ? 5 : 13),
              Text(
                'Every move is part of the adventure. Explore together, '
                'one step at a time.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: compact ? 14 : null,
                  height: compact ? 1.25 : null,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: compact ? 24 : 54),
        Expanded(
          flex: 4,
          child: _TrailIllustration(compact: compact),
        ),
      ],
    );
  }

  Widget _buildModePicker(bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CHOOSE YOUR MOVEMENT STYLE',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: compact ? 16 : 22,
                letterSpacing: compact ? 0.9 : 1.25,
              ),
            ),
            SizedBox(width: compact ? 10 : 16),
            Text(
              'Pick what feels right today',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: compact ? 13 : 18,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 9 : 17),
        SizedBox(
          height: compact ? 128 : 214,
          child: Row(
            children: [
              for (var index = 0; index < MovementMode.values.length; index++) ...[
                if (index > 0) SizedBox(width: compact ? 12 : 19),
                Expanded(
                  child: _ModeCard(
                    mode: MovementMode.values[index],
                    selected: _selectedMode == MovementMode.values[index],
                    focusNode: _modeFocusNodes[index],
                    autofocus: MovementMode.values[index] == MovementMode.gentle,
                    onFocusChange: (hasFocus) {
                      if (hasFocus) _selectMode(MovementMode.values[index]);
                    },
                    onKeyEvent: (event) => _handleModeKey(index, event),
                    onPressed: () => _selectMode(MovementMode.values[index]),
                    compact: compact,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStartButton(bool compact) {
    return Center(
      child: SizedBox(
        width: compact ? 350 : 480,
        height: compact ? 56 : 76,
        child: Focus(
          onKeyEvent: (node, event) => _handleStartKey(event),
          child: TvActionButton(
            label: 'START ADVENTURE',
            icon: Icons.arrow_forward_rounded,
            focusNode: _startFocusNode,
            primary: true,
            onPressed: _startAdventure,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool compact) {
    return Row(
      children: [
        Icon(
          Icons.swap_horiz_rounded,
          color: AppTheme.teal,
          size: compact ? 20 : 27,
        ),
        SizedBox(width: compact ? 7 : 10),
        Text(
          'LEFT / RIGHT  CHOOSE     •     SELECT  START',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: compact ? 10 : 15,
            fontWeight: FontWeight.w800,
            letterSpacing: compact ? 0.6 : 1.15,
          ),
        ),
        const Spacer(),
        Focus(
          onKeyEvent: (node, event) => _handleHelpKey(event),
          child: OutlinedButton.icon(
            focusNode: _helpFocusNode,
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline_rounded, size: 23),
            label: const Text('SETTINGS & HELP'),
          ),
        ),
      ],
    );
  }
}

class _TrailIllustration extends StatelessWidget {
  const _TrailIllustration({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 105 : 166,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 26,
        vertical: compact ? 10 : 22,
      ),
      decoration: BoxDecoration(
        color: const Color(0xBB102A20),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0x6659D9BC)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.teal.withValues(alpha: 0.08),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 62 : 88,
            height: compact ? 62 : 88,
            decoration: BoxDecoration(
              color: AppTheme.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(compact ? 17 : 23),
            ),
            child: Icon(
              Icons.forest_rounded,
              color: AppTheme.teal,
              size: compact ? 40 : 56,
            ),
          ),
            SizedBox(width: compact ? 12 : 22),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THE WILD AWAITS',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: compact ? 14 : 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: compact ? 0.8 : 1.5,
                  ),
                ),
                SizedBox(height: compact ? 4 : 9),
                Text(
                  'Your next great story starts with a move.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: compact ? 11 : 16,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: compact ? 6 : 12),
                Row(
                  children: List.generate(
                    5,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: index == 2 ? 38 : 9,
                      height: 6,
                      decoration: BoxDecoration(
                        color: index == 2
                            ? AppTheme.lime
                            : AppTheme.teal.withValues(alpha: 0.48),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.focusNode,
    required this.autofocus,
    required this.onFocusChange,
    required this.onKeyEvent,
    required this.onPressed,
    required this.compact,
  });

  final MovementMode mode;
  final bool selected;
  final FocusNode focusNode;
  final bool autofocus;
  final ValueChanged<bool> onFocusChange;
  final KeyEventResult Function(KeyEvent event) onKeyEvent;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Focus(
      key: ValueKey('mode-${mode.name}'),
      focusNode: focusNode,
      autofocus: autofocus,
      onFocusChange: onFocusChange,
      onKeyEvent: (node, event) => onKeyEvent(event),
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return AnimatedScale(
            scale: focused ? 1.025 : 1,
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF193B2A)
                    : const Color(0xE610281E),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: focused
                      ? AppTheme.textPrimary
                      : selected
                      ? mode.accent
                      : AppTheme.outline,
                  width: focused ? 3 : (selected ? 2 : 1.5),
                ),
                boxShadow: focused
                    ? [
                        BoxShadow(
                          color: mode.accent.withValues(alpha: 0.22),
                          blurRadius: 26,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(20),
                  focusColor: Colors.transparent,
                  child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 15 : 23,
                    vertical: compact ? 11 : 19,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: compact ? 36 : 48,
                              height: compact ? 36 : 48,
                              decoration: BoxDecoration(
                                color: mode.accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(
                                  compact ? 12 : 15,
                                ),
                              ),
                              child: Icon(
                                mode.icon,
                                color: mode.accent,
                                size: compact ? 23 : 30,
                              ),
                            ),
                            const Spacer(),
                            if (selected)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: mode.accent.withValues(alpha: 0.13),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: mode.accent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SELECTED',
                                      style: TextStyle(
                                        color: mode.accent,
                                        fontSize: compact ? 8 : 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: compact ? 0.3 : 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          mode.label,
                          style: TextStyle(
                            color: mode.accent,
                            fontSize: compact ? 20 : 27,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        SizedBox(height: compact ? 2 : 6),
                        Text(
                          mode.description,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ).copyWith(fontSize: compact ? 12 : 17),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
