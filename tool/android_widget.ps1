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
  foreach ($n in 'ep_widget','ep_widget_s','ep_widget_xs','ep_widget_l') { Copy-Item (Join-Path $src ($n + '.xml')) (Join-Path $res ('layout\' + $n + '.xml')) -Force }
  foreach ($n in 'ep_widget_bg','ep_widget_leaf','ep_widget_progress','ep_widget_blob_a','ep_widget_blob_b','ep_widget_badge','ep_widget_pill') { Copy-Item (Join-Path $src ($n + '.xml')) (Join-Path $res ('drawable\' + $n + '.xml')) -Force }
  Copy-Item (Join-Path $src 'ep_widget_info.xml') (Join-Path $res 'xml\ep_widget_info.xml') -Force
  $kt = Join-Path $root 'android\app\src\main\kotlin\az\ecopoint\widget'
  New-Item -ItemType Directory -Force $kt | Out-Null
  Copy-Item (Join-Path $src 'EpWidgetProvider.kt') (Join-Path $kt 'EpWidgetProvider.kt') -Force

  $t = [IO.File]::ReadAllText($m)
  if ($t -notmatch 'EpWidgetProvider') {
    $rx = '<receiver android:name="az.ecopoint.widget.EpWidgetProvider" android:exported="false">' + "`r`n" +
          '            <intent-filter><action android:name="android.appwidget.action.APPWIDGET_UPDATE"/></intent-filter>' + "`r`n" +
          '            <meta-data android:name="android.appwidget.provider" android:resource="@xml/ep_widget_info"/>' + "`r`n" +
          '        </receiver>' + "`r`n    </application>"
    $t = ([regex]'</application>').Replace($t, $rx, 1)
    [IO.File]::WriteAllText($m, $t, $utf8)
  }
  Write-Host "Vidjet yamasi tetbiq olundu." -ForegroundColor Green
}
