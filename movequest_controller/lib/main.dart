import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'movement_detector.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MoveQuestControllerApp());
}

class MoveQuestControllerApp extends StatelessWidget {
  const MoveQuestControllerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOVEQUEST Pose Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7BE0B2),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101513),
        useMaterial3: true,
      ),
      home: const PoseTestScreen(),
    );
  }
}

class PoseTestScreen extends StatefulWidget {
  const PoseTestScreen({super.key});

  @override
  State<PoseTestScreen> createState() => _PoseTestScreenState();
}

class _PoseTestScreenState extends State<PoseTestScreen>
    with WidgetsBindingObserver {
  static const _methods = MethodChannel('movequest/pose_camera');
  static const _poseEvents = EventChannel('movequest/pose_results');

  final _detector = MovementDetector();
  StreamSubscription<Object?>? _subscription;
  PoseFrame? _frame;
  Movement _movement = Movement.none;
  String _trackingStatus = 'Initializing';
  String? _errorMessage;
  bool _hasCameraPermission = false;
  bool _permissionPermanentlyDenied = false;
  bool _isTracking = false;
  bool _isStarting = false;
  bool _isFrontCamera = true;
  int _movementCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = _poseEvents.receiveBroadcastStream().listen(
      _handlePoseEvent,
      onError: _handlePoseError,
    );
    unawaited(_checkPermission());
  }

  Future<void> _checkPermission() async {
    try {
      final granted =
          await _methods.invokeMethod<bool>('checkCameraPermission') ?? false;
      if (mounted) setState(() => _hasCameraPermission = granted);
    } on PlatformException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    }
  }

  void _handlePoseEvent(Object? event) {
    if (!mounted || event is! Map) return;
    final frame = PoseFrame.fromEvent(Map<Object?, Object?>.from(event));
    final update = _detector.update(
      frame.landmarks,
      mirrored: frame.frontCamera,
    );
    setState(() {
      _frame = frame;
      _movement = update.movement;
      _trackingStatus = switch (frame.status) {
        'tracking' => 'Tracking',
        'noPerson' => 'No person detected',
        'error' => 'Tracking error',
        _ => 'Initializing',
      };
      _errorMessage = frame.errorMessage;
      _isTracking = frame.status == 'tracking' || frame.status == 'noPerson';
      _isFrontCamera = frame.frontCamera;
      _movementCount += update.events.length;
    });
  }

  void _handlePoseError(Object error) {
    if (!mounted) return;
    setState(() {
      _trackingStatus = 'Tracking error';
      _errorMessage = error.toString();
      _isTracking = false;
    });
  }

  Future<void> _startTracking() async {
    if (_isStarting) return;
    setState(() {
      _isStarting = true;
      _trackingStatus = 'Initializing';
      _errorMessage = null;
    });
    try {
      final permission = await _methods.invokeMapMethod<String, bool>(
        'requestCameraPermission',
      );
      final granted = permission?['granted'] ?? false;
      if (mounted) {
        setState(() {
          _hasCameraPermission = granted;
          _permissionPermanentlyDenied =
              permission?['permanentlyDenied'] ?? false;
        });
      }
      if (!granted) return;

      await _methods.invokeMethod<void>('startTracking');
      if (mounted) {
        setState(() {
          _isTracking = true;
          _trackingStatus = 'Initializing';
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _trackingStatus = 'Tracking error';
          _errorMessage = error.message ?? error.code;
        });
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _stopTracking() async {
    try {
      await _methods.invokeMethod<void>('stopTracking');
    } on PlatformException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message ?? error.code);
    } finally {
      _detector.reset();
      if (mounted) {
        setState(() {
          _isTracking = false;
          _isStarting = false;
          _frame = null;
          _movement = Movement.none;
          _trackingStatus = 'Initializing';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    try {
      final front = await _methods.invokeMethod<bool>('switchCamera');
      if (mounted && front != null) setState(() => _isFrontCamera = front);
    } on PlatformException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message ?? error.code);
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await _methods.invokeMethod<void>('openAppSettings');
    } on PlatformException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message ?? error.code);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        (_isTracking || _isStarting)) {
      unawaited(_stopTracking());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    unawaited(_methods.invokeMethod<void>('stopTracking').catchError((_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'MOVEQUEST · POSE TEST',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: _CameraPanel(
                  frame: _frame,
                  status: _trackingStatus,
                  isTracking: _isTracking,
                  isStarting: _isStarting,
                  hasPermission: _hasCameraPermission,
                  permissionPermanentlyDenied: _permissionPermanentlyDenied,
                  onStart: _startTracking,
                  onOpenSettings: _openAppSettings,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 4,
                child: _MetricsPanel(
                  frame: _frame,
                  movement: _movement,
                  movementCount: _movementCount,
                  isTracking: _isTracking,
                  isFrontCamera: _isFrontCamera,
                  errorMessage: _errorMessage,
                  onStart: _startTracking,
                  onStop: _stopTracking,
                  onSwitchCamera: _switchCamera,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraPanel extends StatelessWidget {
  const _CameraPanel({
    required this.frame,
    required this.status,
    required this.isTracking,
    required this.isStarting,
    required this.hasPermission,
    required this.permissionPermanentlyDenied,
    required this.onStart,
    required this.onOpenSettings,
  });

  final PoseFrame? frame;
  final String status;
  final bool isTracking;
  final bool isStarting;
  final bool hasPermission;
  final bool permissionPermanentlyDenied;
  final VoidCallback onStart;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const AndroidView(
            viewType: 'movequest/camera_preview',
            layoutDirection: TextDirection.ltr,
          ),
          if (frame?.landmarks.isNotEmpty ?? false)
            CustomPaint(painter: _SkeletonPainter(frame!)),
          Positioned(
            left: 12,
            top: 12,
            child: _StatusChip(status: status, isTracking: isTracking),
          ),
          if (!hasPermission || (!isTracking && !isStarting))
            ColoredBox(
              color: const Color(0xD9101513),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_search, size: 38),
                      const SizedBox(height: 12),
                      Text(
                        hasPermission
                            ? (isStarting
                                  ? 'Initializing pose detector…'
                                  : 'Camera is stopped')
                            : 'Camera access is needed to track a pose.',
                        textAlign: TextAlign.center,
                      ),
                      if (!hasPermission) ...[
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: permissionPermanentlyDenied
                              ? onOpenSettings
                              : onStart,
                          child: Text(
                            permissionPermanentlyDenied
                                ? 'Open app settings'
                                : 'Grant camera access',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({
    required this.frame,
    required this.movement,
    required this.movementCount,
    required this.isTracking,
    required this.isFrontCamera,
    required this.errorMessage,
    required this.onStart,
    required this.onStop,
    required this.onSwitchCamera,
  });

  final PoseFrame? frame;
  final Movement movement;
  final int movementCount;
  final bool isTracking;
  final bool isFrontCamera;
  final String? errorMessage;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    final isExperimental = movement.isShift;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(label: 'FPS', value: _fps(frame)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Infer (ms)',
                value: frame?.inferenceMs == null
                    ? '—'
                    : '${frame!.inferenceMs!.toStringAsFixed(1)} ms',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Quality',
                value: frame?.quality == null
                    ? '—'
                    : '${(frame!.quality! * 100).clamp(0, 100).round()}%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A221E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_run, color: Color(0xFF7BE0B2)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        movement.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        isExperimental
                            ? 'Experimental lean estimate · $movementCount events'
                            : '$movementCount movement events',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            errorMessage!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFFFA69A), fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isTracking ? onStop : onStart,
                icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
                label: Text(isTracking ? 'Stop tracking' : 'Start tracking'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: isTracking ? onSwitchCamera : null,
              tooltip: 'Switch camera',
              icon: const Icon(Icons.cameraswitch),
            ),
          ],
        ),
      ],
    );
  }

  String _fps(PoseFrame? frame) {
    final value = frame?.fps;
    return value == null ? '—' : value.toStringAsFixed(1);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF1A221E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.isTracking});

  final String status;
  final bool isTracking;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD101513),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.circle,
              size: 9,
              color: isTracking ? const Color(0xFF7BE0B2) : Colors.amber,
            ),
            const SizedBox(width: 7),
            Text(status, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter(this.frame);

  final PoseFrame frame;

  static const _connections = <(int, int)>[
    (11, 12),
    (11, 13),
    (13, 15),
    (12, 14),
    (14, 16),
    (11, 23),
    (12, 24),
    (23, 24),
    (23, 25),
    (25, 27),
    (24, 26),
    (26, 28),
    (27, 31),
    (28, 32),
  ];
  static const _visibleJoints = <int>{
    11,
    12,
    13,
    14,
    15,
    16,
    23,
    24,
    25,
    26,
    27,
    28,
  };

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFF7BE0B2)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final joint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final points = frame.landmarks;

    for (final (from, to) in _connections) {
      if (from >= points.length || to >= points.length) continue;
      if (!_isVisible(points[from]) || !_isVisible(points[to])) continue;
      canvas.drawLine(
        _mapPoint(points[from], size),
        _mapPoint(points[to], size),
        line,
      );
    }
    for (final index in _visibleJoints) {
      if (index >= points.length || !_isVisible(points[index])) continue;
      canvas.drawCircle(_mapPoint(points[index], size), 5, joint);
    }
  }

  bool _isVisible(PosePoint point) =>
      math.max(point.visibility, point.presence) >= 0.3;

  Offset _mapPoint(PosePoint point, Size size) {
    var x = frame.frontCamera ? 1 - point.x : point.x;
    var y = point.y;
    final imageAspect = frame.imageWidth / frame.imageHeight;
    final viewAspect = size.width / size.height;
    if (imageAspect > viewAspect) {
      final visibleWidth = viewAspect / imageAspect;
      x = (x - (1 - visibleWidth) / 2) / visibleWidth;
    } else {
      final visibleHeight = imageAspect / viewAspect;
      y = (y - (1 - visibleHeight) / 2) / visibleHeight;
    }
    return Offset(x * size.width, y * size.height);
  }

  @override
  bool shouldRepaint(covariant _SkeletonPainter oldDelegate) =>
      oldDelegate.frame != frame;
}

class PoseFrame {
  const PoseFrame({
    required this.status,
    required this.landmarks,
    required this.imageWidth,
    required this.imageHeight,
    required this.frontCamera,
    this.quality,
    this.fps,
    this.inferenceMs,
    this.errorMessage,
  });

  final String status;
  final List<PosePoint> landmarks;
  final int imageWidth;
  final int imageHeight;
  final bool frontCamera;
  final double? quality;
  final double? fps;
  final double? inferenceMs;
  final String? errorMessage;

  factory PoseFrame.fromEvent(Map<Object?, Object?> event) {
    final points = event['landmarks'];
    final rotationDegrees =
        ((event['rotationDegrees'] as num?)?.toInt() ?? 0) % 360;
    return PoseFrame(
      status: event['status'] as String? ?? 'initializing',
      landmarks: points is List
          ? points
                .whereType<Map<Object?, Object?>>()
                .map(PosePoint.fromEvent)
                .map((point) => _rotatePosePoint(point, rotationDegrees))
                .toList(growable: false)
          : const [],
      imageWidth: (event['imageWidth'] as num?)?.toInt() ?? 4,
      imageHeight: (event['imageHeight'] as num?)?.toInt() ?? 3,
      frontCamera: event['frontCamera'] as bool? ?? true,
      quality: (event['quality'] as num?)?.toDouble(),
      fps: (event['fps'] as num?)?.toDouble(),
      inferenceMs: (event['inferenceMs'] as num?)?.toDouble(),
      errorMessage: event['message'] as String?,
    );
  }
}

PosePoint _rotatePosePoint(PosePoint point, int rotationDegrees) {
  final (x, y) = switch (rotationDegrees) {
    90 => (1 - point.y, point.x),
    180 => (1 - point.x, 1 - point.y),
    270 => (point.y, 1 - point.x),
    _ => (point.x, point.y),
  };
  return PosePoint(
    x: x,
    y: y,
    visibility: point.visibility,
    presence: point.presence,
  );
}
