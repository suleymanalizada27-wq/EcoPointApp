#!/usr/bin/env bash
# One-time platform bootstrap. Run from the project root on a machine with the
# Flutter SDK (>= 3.27) installed:   bash tool/bootstrap.sh
#
# Generates android/ and ios/ with `flutter create` (so they always match your
# Flutter version) and then patches in what EcoPoint needs: camera + location
# permissions, minSdk 23, iOS 13 and usage descriptions.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v flutter >/dev/null || { echo "flutter not found on PATH"; exit 1; }

flutter create --platforms=android,ios --org az.ecopoint --project-name ecopoint_pro .
flutter pub get

python3 - <<'PY'
import re, pathlib

# ── Android manifest permissions ──
m = pathlib.Path('android/app/src/main/AndroidManifest.xml')
t = m.read_text()
perms = [
  'android.permission.INTERNET',
  'android.permission.CAMERA',
  'android.permission.ACCESS_COARSE_LOCATION',
  'android.permission.ACCESS_FINE_LOCATION',
]
add = ''.join(f'    <uses-permission android:name="{p}"/>\n' for p in perms if p not in t)
t = t.replace('<application', add + '    <uses-feature android:name="android.hardware.camera" android:required="false"/>\n    <application', 1) if 'uses-feature' not in t else t.replace('<application', add + '    <application', 1)
t = re.sub(r'android:label="[^"]*"', 'android:label="EcoPoint"', t, count=1)
m.write_text(t)

# ── Android minSdk (camera/ML Kit and Firebase need >= 23) ──
for name in ('android/app/build.gradle', 'android/app/build.gradle.kts'):
    p = pathlib.Path(name)
    if not p.exists(): continue
    g = p.read_text()
    g = re.sub(r'minSdk(Version)?\s*=?\s*flutter\.minSdkVersion', 'minSdk = 23', g)
    g = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23', g)
    p.write_text(g)

# ── iOS Info.plist usage strings ──
p = pathlib.Path('ios/Runner/Info.plist')
s = p.read_text()
strings = {
  'NSCameraUsageDescription': 'EcoPoint uses the camera to scan smart-bin and friend QR codes.',
  'NSLocationWhenInUseUsageDescription': 'EcoPoint uses your location to show and sort nearby smart bins.',
}
for k, v in strings.items():
    if k not in s:
        s = s.replace('</dict>\n</plist>', f'\t<key>{k}</key>\n\t<string>{v}</string>\n</dict>\n</plist>')
p.write_text(s)

# ── iOS deployment target ──
pod = pathlib.Path('ios/Podfile')
if pod.exists():
    c = pod.read_text()
    c = re.sub(r"#?\s*platform :ios, '[^']*'", "platform :ios, '13.0'", c, count=1)
    pod.write_text(c)
PY

cat <<'MSG'

Platform folders created and patched.

Still required (not automated, needs YOUR Firebase account):
  1. dart pub global activate flutterfire_cli
  2. flutterfire configure --project=ecopoint-b3d60 --platforms=android,ios
     (overwrites lib/firebase_options.dart with real values and downloads
      google-services.json / GoogleService-Info.plist)
  3. Android Google sign-in: add your debug/release SHA-1 + SHA-256 in the
     Firebase console, re-download google-services.json.
  4. iOS Google sign-in: add the REVERSED_CLIENT_ID URL scheme to Info.plist.
  5. Deploy the backend (see README.md → Backend).
Then: flutter analyze && flutter test && flutter run
MSG
