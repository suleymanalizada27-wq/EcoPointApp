# Adds the EcoPoint home-screen widget (balance + streak) to the Android project. Idempotent.
# Run from the project root AFTER `flutter create`/`flutter pub get`:   . .\tool\android_widget.ps1
# If the widget ever breaks the Android build, just do not run this script
# (the app works without it; the Flutter side ignores a missing widget).
$utf8 = New-Object System.Text.UTF8Encoding($false)
$root = (Get-Location).Path
$m = Join-Path $root 'android\app\src\main\AndroidManifest.xml'
if (-not (Test-Path $m)) {
  Write-Host "android\ qovluqu tapilmadi." -ForegroundColor Red
} else {
  $src = Join-Path $root 'tool\android_res\widget'
  $res = Join-Path $root 'android\app\src\main\res'
  foreach ($d in 'layout','drawable','xml') { New-Item -ItemType Directory -Force (Join-Path $res $d) | Out-Null }
  foreach ($n in 'ep_widget','ep_widget_s','ep_widget_xs','ep_widget_l','ep_widget_xl') { Copy-Item (Join-Path $src ($n + '.xml')) (Join-Path $res ('layout\' + $n + '.xml')) -Force }
  foreach ($n in 'ep_widget_bg','ep_widget_flame','ep_widget_flame_1','ep_widget_flame_2','ep_widget_flame_3','ep_widget_seg_on','ep_widget_seg_off','ep_widget_divider','ep_widget_pill','ep_widget_btn') { Copy-Item (Join-Path $src ($n + '.xml')) (Join-Path $res ('drawable\' + $n + '.xml')) -Force }
  New-Item -ItemType Directory -Force (Join-Path $res 'drawable-nodpi') | Out-Null
  Copy-Item (Join-Path $src 'ep_widget_logo.png') (Join-Path $res 'drawable-nodpi\ep_widget_logo.png') -Force
  # EcoFriend static PNGs (home-screen widgets cannot play animated WebP)
  foreach ($n in 'normal','sad','excited','cheering','proud') { Copy-Item (Join-Path $src ('ecofriend\ecofriend_' + $n + '.png')) (Join-Path $res ('drawable-nodpi\ecofriend_' + $n + '.png')) -Force }
  foreach ($n in 'ep_widget_info','ep_widget_info_xs','ep_widget_info_m','ep_widget_info_l','ep_widget_info_xl') { Copy-Item (Join-Path $src ($n + '.xml')) (Join-Path $res ('xml\' + $n + '.xml')) -Force }
  $kt = Join-Path $root 'android\app\src\main\kotlin\az\ecopoint\widget'
  New-Item -ItemType Directory -Force $kt | Out-Null
  Copy-Item (Join-Path $src 'EpWidgetProvider.kt') (Join-Path $kt 'EpWidgetProvider.kt') -Force

  # Five picker entries: 2x1, 2x2 (adaptive), 3x2, 4x2, 4x4. Idempotent per receiver.
  $t = [IO.File]::ReadAllText($m)
  $entries = @(
    @{ cls = 'EpWidgetXsProvider'; label = 'EcoPoint 2x1'; xml = 'ep_widget_info_xs' },
    @{ cls = 'EpWidgetProvider';   label = 'EcoPoint 2x2'; xml = 'ep_widget_info' },
    @{ cls = 'EpWidgetMProvider';  label = 'EcoPoint 3x2'; xml = 'ep_widget_info_m' },
    @{ cls = 'EpWidgetLProvider';  label = 'EcoPoint 4x2'; xml = 'ep_widget_info_l' },
    @{ cls = 'EpWidgetXlProvider'; label = 'EcoPoint 4x4'; xml = 'ep_widget_info_xl' }
  )
  foreach ($e in $entries) {
    $full = 'az.ecopoint.widget.' + $e.cls
    if ($t -match [regex]::Escape('android:name="' + $full + '"')) {
      # already registered: just make sure it carries the picker label
      continue
    }
    $rx = '<receiver android:name="' + $full + '" android:label="' + $e.label + '" android:exported="false">' + "`r`n" +
          '            <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE"/></intent-filter>' + "`r`n" +
          '            <meta-data android:name="android.appwidget.provider" android:resource="@xml/' + $e.xml + '"/>' + "`r`n" +
          '        </receiver>' + "`r`n    </application>"
    $t = ([regex]'</application>').Replace($t, $rx, 1)
  }
  # the original 2x2 receiver (installed earlier) had no label: add it
  $t = $t -replace '<receiver android:name="az\.ecopoint\.widget\.EpWidgetProvider" android:exported="false">', '<receiver android:name="az.ecopoint.widget.EpWidgetProvider" android:label="EcoPoint 2x2" android:exported="false">'
  [IO.File]::WriteAllText($m, $t, $utf8)
  Write-Host "Vidjet yamasi tetbiq olundu." -ForegroundColor Green
}
