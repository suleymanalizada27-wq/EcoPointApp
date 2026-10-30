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

# ---- Crashlytics Gradle plugin + invite App Links (idempotent) ----
$appHost = 'ecopoint-api-2vey.onrender.com'
$android = Join-Path (Get-Location).Path 'android'
$files = @(
  @{ Path = (Join-Path $android 'settings.gradle');         Settings = $true },
  @{ Path = (Join-Path $android 'settings.gradle.kts');     Settings = $true },
  @{ Path = (Join-Path $android 'app\build.gradle');        Settings = $false },
  @{ Path = (Join-Path $android 'app\build.gradle.kts');    Settings = $false }
)
foreach ($f in $files) {
  if (Test-Path $f.Path) {
    $lines = [IO.File]::ReadAllLines($f.Path)
    $joined = $lines -join "`n"
    if ($joined -notmatch 'firebase\.crashlytics' -and $joined -match 'com\.google\.gms\.google-services') {
      $out = New-Object System.Collections.Generic.List[string]
      foreach ($l in $lines) {
        $out.Add($l)
        if ($l -match 'com\.google\.gms\.google-services') {
          $n = $l.Replace('com.google.gms.google-services', 'com.google.firebase.crashlytics')
          if ($f.Settings) { $n = [regex]::Replace($n, 'version\s+["''][^"'']+["'']', 'version "3.0.2"') }
          $out.Add($n)
        }
      }
      [IO.File]::WriteAllLines($f.Path, $out, $utf8)
      Write-Host ("Crashlytics plugin elave olundu: " + $f.Path) -ForegroundColor Green
    }
  }
}
if (Test-Path $m) {
  $t = [IO.File]::ReadAllText($m)
  if ($t -notmatch 'pathPrefix="/invite"') {
    $filter = '<meta-data android:name="flutter_deeplinking_enabled" android:value="true"/>' + "`r`n" +
      '            <intent-filter android:autoVerify="true">' + "`r`n" +
      '                <action android:name="android.intent.action.VIEW"/>' + "`r`n" +
      '                <category android:name="android.intent.category.DEFAULT"/>' + "`r`n" +
      '                <category android:name="android.intent.category.BROWSABLE"/>' + "`r`n" +
      '                <data android:scheme="https" android:host="' + $appHost + '" android:pathPrefix="/invite"/>' + "`r`n" +
      '            </intent-filter>' + "`r`n" +
      '        </activity>'
    $t = ([regex]'</activity>').Replace($t, $filter, 1)
    [IO.File]::WriteAllText($m, $t, $utf8)
    Write-Host "Devet linki (App Links) manifestə elave olundu." -ForegroundColor Green
  }
}
