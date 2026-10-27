# Creates the Play Store RELEASE signing key OUTSIDE the repo and wires Gradle to it.
# Run from the project root:   . .\tool\make_keystore.ps1
# The key file + passwords are NEVER committed (android/key.properties is git-ignored).
# BACK THE KEY UP (e.g. password manager + USB). Losing it can lock you out of updates.
$utf8 = New-Object System.Text.UTF8Encoding($false)
$root = (Get-Location).Path
$dir = Join-Path $env:USERPROFILE 'ecopoint-keys'
New-Item -ItemType Directory -Force $dir | Out-Null
$jks = Join-Path $dir 'ecopoint-release.jks'
$pass = Read-Host 'Yeni keystore parolu (>=8 simvol, yadda saxla!)'
if (-not (Test-Path $jks)) {
  & keytool -genkeypair -v -keystore $jks -alias ecopoint -keyalg RSA -keysize 2048 -validity 10000 `
    -storepass $pass -keypass $pass -dname 'CN=EcoPoint, O=GreenLine Group, C=AZ'
}
$props = "storePassword=$pass`r`nkeyPassword=$pass`r`nkeyAlias=ecopoint`r`nstoreFile=" + ($jks -replace '\\','/') + "`r`n"
[IO.File]::WriteAllText((Join-Path $root 'android\key.properties'), $props, $utf8)

$g = Join-Path $root 'android\app\build.gradle'
if (-not (Test-Path $g)) { $g = Join-Path $root 'android\app\build.gradle.kts' }
$t = [IO.File]::ReadAllText($g)
if ($g.EndsWith('.kts')) {
  Write-Host "build.gradle.kts tapildi - docs\PLAY_STORE.md-deki Kotlin hissesini ele elave et." -ForegroundColor Yellow
} elseif ($t -notmatch 'keystoreProperties') {
  $load = "def keystoreProperties = new Properties()`r`ndef keystorePropertiesFile = rootProject.file('key.properties')`r`nif (keystorePropertiesFile.exists()) { keystoreProperties.load(new FileInputStream(keystorePropertiesFile)) }`r`n`r`nandroid {"
  $t = ([regex]'android\s*\{').Replace($t, $load, 1)
  $signing = "    signingConfigs {`r`n        release {`r`n            if (keystoreProperties['storeFile']) {`r`n                keyAlias keystoreProperties['keyAlias']`r`n                keyPassword keystoreProperties['keyPassword']`r`n                storeFile file(keystoreProperties['storeFile'])`r`n                storePassword keystoreProperties['storePassword']`r`n            }`r`n        }`r`n    }`r`n`r`n    buildTypes {"
  $t = ([regex]'buildTypes\s*\{').Replace($t, $signing, 1)
  $t = $t -replace 'signingConfig\s+signingConfigs\.debug', 'signingConfig signingConfigs.release'
  [IO.File]::WriteAllText($g, $t, $utf8)
  Write-Host "Gradle imza ayarlari yazildi." -ForegroundColor Green
}
Write-Host "SHA-1 / SHA-256 (Firebase-e elave et):" -ForegroundColor Cyan
& keytool -list -v -keystore $jks -alias ecopoint -storepass $pass | Select-String 'SHA1|SHA256'
