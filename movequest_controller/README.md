# MOVEQUEST Controller Pose Feasibility Prototype

Independent Android phone companion prototype. The existing Flutter TV game is
left untouched.

## Requirements

- Flutter 3.47 or newer and Dart 3.13 or newer
- Android SDK and a connected Android phone or emulator
- Android API 24 or newer
- JDK 17 or newer

The project uses the Flutter toolchain's configured Android SDK and JDK. The
pose model is bundled into the app; camera frames and landmarks are processed
locally and are not uploaded or saved.

## Run and install

From the repository root:

```powershell
cd movequest_controller
flutter pub get
flutter devices
flutter run -d <device-id>
```

To build release APKs for each Android architecture and manually install
the arm64 APK on a realme P1 5G with USB debugging enabled:

```powershell
cd movequest_controller
flutter build apk --release --split-per-abi
$deviceId = 'YOUR_DEVICE_ID'
& 'D:\Android\Sdk\platform-tools\adb.exe' -s $deviceId install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
& 'D:\Android\Sdk\platform-tools\adb.exe' -s $deviceId shell am start -n com.movequest.movequest_controller/.MainActivity
```

Alternatively, `flutter run -d <device-id>` builds, installs, and launches the
app directly. Find the phone's device ID with `flutter devices`.
The arm64 release APK built here was 34.2 MB; debug builds are larger.

## Implementation

- Google MediaPipe Tasks Vision for Android (`0.10.35`), Pose Landmarker Lite
  model, one pose, CPU delegate.
- The model is Google's
  [Pose Landmarker Lite bundle](https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/1/pose_landmarker_lite.task),
  packaged in `android/app/src/main/assets`.
- CameraX (`1.4.2`) supplies the native preview and image analysis.
- The preview uses CameraX's compatible rendering mode so Flutter can draw
  the skeleton above it. Camera rotation is applied to landmarks before both
  overlay rendering and movement classification.
- The analyzer uses `STRATEGY_KEEP_ONLY_LATEST`; inference runs in live-stream
  mode and additional frames are dropped while an inference is outstanding.
- Android code shrinking and resource shrinking are disabled for release
  builds. R8 shrinking removed MediaPipe graph/protobuf metadata needed during
  on-device task initialization.
- FPS is the observed result rate over a one-second window. The displayed
  inference time measures native submission-to-result callback latency; it
  includes asynchronous task scheduling as well as model execution.
- Movement events use normalized shoulder, wrist, and hip landmarks with
  exponential smoothing, separate enter/exit thresholds, and stable-frame
  requirements. Lean estimates are experimental screen-left/right hip-to-
  shoulder offsets, not validated body-weight measurements.

The only requested runtime permission is camera access. No microphone,
location, or storage permission is requested. Flutter's debug/profile
manifests include internet access for development tooling; this app does not
use a network for camera or pose processing, and camera data stays on-device.

## Limitations

Use a stationary phone with the whole body visible and adequate lighting.
Camera angle, distance, loose clothing, motion blur, self-occlusion, and
landmarks leaving the frame can reduce tracking quality or cause missed
gestures. The lean heuristic measures apparent horizontal hip displacement
relative to the shoulders; it cannot establish a real body-weight shift.

The available emulator is an Android TV emulator, not a physical phone camera
validation target. Pose detection was exercised on the realme P1 5G instead.

The emulator smoke test opened CameraX and MediaPipe without a runtime crash
and briefly reported approximately 17 observed results per second and 45 ms
submit-to-result latency. Its synthetic camera view did not produce a person
detection; these figures are not a realme P1 5G benchmark.

The arm64 release APK was installed on a realme P1 5G running Android 16 (API
36). The live preview, upright aligned skeleton overlay, and both-arms-raised
recognition were verified. During a brief user test, the app reported about
9-14 observed FPS and 40-140 ms submit-to-result latency; these are
device-specific observations, not a sustained benchmark. Individual
left/right arm raises, camera switching, and the experimental lean estimate
still need physical-device validation.
