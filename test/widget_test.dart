import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:movequest_tv/gameplay/restore_wild_engine.dart';
import 'package:movequest_tv/main.dart';
import 'package:movequest_tv/models/movement_mode.dart';
import 'package:movequest_tv/screens/mission_screen.dart';

void main() {
  testWidgets('selects a mode, starts the mission and moves with the remote', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MoveQuestApp());

    expect(find.text('MOVEQUEST'), findsOneWidget);
    expect(find.text('Play. Move. Progress.'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('mode-active')),
        matching: find.text('SELECTED'),
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('RESTORE THE WILD'), findsOneWidget);
    expect(find.textContaining('ACTIVE MODE'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(find.text('LEFT / RIGHT  MOVE'), findsOneWidget);
    expect(find.text('UP / SELECT  REACH'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(find.text('1 / 6'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('MOVEQUEST'), findsOneWidget);
  });

  testWidgets('returns from mission results to the previous screen remotely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final completedMission = RestoreWildEngine(MovementMode.gentle)
      ..start()
      ..energyCollected = RestoreWildEngine.objective
      ..status = MissionStatus.won;
    var missionForResults = completedMission;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                autofocus: true,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MissionScreen(
                      mode: MovementMode.gentle,
                      engine: missionForResults,
                    ),
                  ),
                ),
                child: const Text('HOME SCREEN'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('THE WILD IS RESTORED!'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('HOME SCREEN'), findsOneWidget);

    missionForResults = RestoreWildEngine(MovementMode.gentle)
      ..start()
      ..lives = 0
      ..status = MissionStatus.lost;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('THE FOREST NEEDS YOU'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(find.text('LEFT / RIGHT  MOVE'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('HOME SCREEN'), findsOneWidget);
  });
}
