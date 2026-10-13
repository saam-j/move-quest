# MOVEQUEST TV

A family-friendly, fitness-oriented motion game prototype built with Flutter for
the Android TV emulator. Choose a movement mode, then play **Restore the Wild**:
collect six energy sparks, avoid thorny obstacles, and restore the forest. The
mission is fully playable with keyboard or Android TV remote controls and does
not require a camera, network, backend, or AI functionality.

## Run on the Android TV emulator

Flutter 3.47 and later do not support Android's 32-bit `x86` emulator ABI.
Changing the Android API level alone does not fix this: the installed Android TV
API 34 and API 36 system images are both `x86`, so Flutter lists them as
`unsupported`.

Create an Android TV AVD with a 64-bit `x86_64` system image. The Android TV
API 36 image is available from the Android SDK:

```powershell
& 'D:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat' `
  'system-images;android-36;android-tv;x86_64'

& 'D:\Android\Sdk\cmdline-tools\latest\bin\avdmanager.bat' create avd `
  --name 'Television_1080p_x64' `
  --package 'system-images;android-36;android-tv;x86_64' `
  --device 'tv_1080p'

& 'D:\Android\Sdk\emulator\emulator.exe' -avd 'Television_1080p_x64'
```

Wait for the emulator to finish booting, then confirm Flutter lists it as a
supported device:

```powershell
flutter devices
flutter run -d emulator-5554
```

If the emulator has a different device ID, use the ID shown by `flutter devices`.
You can also create an Android TV AVD with an `x86_64` system image in Android
Studio's Device Manager; avoid images whose ABI is only `x86`.

As a manual-install fallback, build and launch the debug APK with ADB:

```powershell
flutter build apk --debug
& 'D:\Android\Sdk\platform-tools\adb.exe' install -r build\app\outputs\flutter-apk\app-debug.apk
& 'D:\Android\Sdk\platform-tools\adb.exe' shell am start -n com.example.movequest_tv/.MainActivity
```

On the home screen, use left/right to choose a movement mode and Select/Enter to
open the mission briefing. In **Restore the Wild**, left/right move between the
three paths and Up/Select/Enter/Space reach for an energy spark. Avoid thorns:
three hits or running out of the 90-second timer ends the mission. Collect six
sparks to win. The results screen offers Play Again and Return Home. Scores are
for the selected mode and are not a measure of physical effort.

Choose **Settings & Help** on the home screen for the controls reminder.
Android Back also returns to the home screen.

This prototype targets the Android TV emulator only. Amazon Fire TV
compatibility has not been verified.
