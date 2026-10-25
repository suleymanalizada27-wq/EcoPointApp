# Idempotent Android tweaks for push notifications + https-only traffic.
# Run from the project root:   . .\tool\android_patch.ps1
$utf8 = New-Object System.Text.UTF8Encoding($false)
$root = (Get-Location).Path
$m = Join-Path $root 'android\app\src\main\AndroidManifest.xml'
if (-not (Test-Path $m)) {
  Write-Host "android\ qovluqu tapilmadi (proyekt kokunde isletdiyine emin ol)." -ForegroundColor Red
} else {
  $t = [IO.File]::ReadAllText($m)

  if ($t -notmatch 'POST_NOTIFICATIONS') {
    $perm = '<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>' + "`r`n    <application"
    $t = ([regex]'<application').Replace($t, $perm, 1)
  }
  if ($t -notmatch 'default_notification_icon') {
    $meta = '<meta-data android:name="com.google.firebase.messaging.default_notification_icon" android:resource="@drawable/ic_stat_ecopoint"/>' + "`r`n" +
            '        <meta-data android:name="com.google.firebase.messaging.default_notification_color" android:resource="@color/ecopoint_notification"/>' + "`r`n    </application>"
    $t = ([regex]'</application>').Replace($t, $meta, 1)
  }
  # The API is https now; plain-http traffic is no longer needed.
  $t = $t -replace ' android:usesCleartextTraffic="true"', ''
  [IO.File]::WriteAllText($m, $t, $utf8)

  $res = Join-Path $root 'android\app\src\main\res'
  New-Item -ItemType Directory -Force (Join-Path $res 'drawable') | Out-Null
  New-Item -ItemType Directory -Force (Join-Path $res 'values') | Out-Null
  Copy-Item (Join-Path $root 'tool\android_res\ic_stat_ecopoint.xml') (Join-Path $res 'drawable\ic_stat_ecopoint.xml') -Force
  Copy-Item (Join-Path $root 'tool\android_res\colors_ecopoint.xml') (Join-Path $res 'values\colors_ecopoint.xml') -Force
  Write-Host "Android yamasi tetbiq olundu." -ForegroundColor Green
}
