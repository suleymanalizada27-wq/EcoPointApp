# Registers this PC's Android signing fingerprints with Firebase so that
# Google sign-in works. Run from the project root:   . .\tool\google_sha.ps1
$projectId = 'ecopoint-suleyman-2026'
$ks = Join-Path $HOME '.android\debug.keystore'
if (-not (Test-Path $ks)) {
  Write-Host "debug.keystore tapilmadi: evvelce bir defe 'flutter build apk' islet." -ForegroundColor Red
} else {
  $out = & keytool -list -v -keystore $ks -alias androiddebugkey -storepass android -keypass android 2>&1 | Out-String
  $sha1   = ([regex]'SHA1:\s*([0-9A-Fa-f:]+)').Match($out).Groups[1].Value
  $sha256 = ([regex]'SHA256:\s*([0-9A-Fa-f:]+)').Match($out).Groups[1].Value
  $opts = Get-Content 'lib\firebase_options.dart' -Raw
  $appId = ([regex]"appId:\s*'(1:[0-9]+:android:[0-9a-f]+)'").Match($opts).Groups[1].Value
  Write-Host "App ID : $appId"
  Write-Host "SHA-1  : $sha1"
  Write-Host "SHA-256: $sha256"
  if ($sha1 -and $appId) {
    firebase apps:android:sha:create $appId $sha1 --project $projectId
    if ($sha256) { firebase apps:android:sha:create $appId $sha256 --project $projectId }
    Write-Host "Hazirdir. (Artiq movcud oldugunu deyen xeta normaldir.)" -ForegroundColor Green
  } else {
    Write-Host "SHA oxunmadi: keytool PATH-dadir? Java qurulubmu?" -ForegroundColor Red
  }
}
