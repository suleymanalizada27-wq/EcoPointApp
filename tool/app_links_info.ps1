# Reads this PC's Android package name and debug SHA-256 (for App Links).
# Dot-source it:  . .\tool\app_links_info.ps1   -> sets $EpPackage and $EpSha256
$EpPackage = ''
$EpSha256 = ''
$gs = Join-Path (Get-Location).Path 'android\app\google-services.json'
if (Test-Path $gs) {
  $EpPackage = ([regex]'"package_name"\s*:\s*"([^"]+)"').Match([IO.File]::ReadAllText($gs)).Groups[1].Value
}
$ks = Join-Path $HOME '.android\debug.keystore'
if (Test-Path $ks) {
  $o = & keytool -list -v -keystore $ks -alias androiddebugkey -storepass android -keypass android 2>&1 | Out-String
  $EpSha256 = ([regex]'SHA256:\s*([0-9A-Fa-f:]+)').Match($o).Groups[1].Value
}
Write-Host "Paket: $EpPackage" -ForegroundColor Gray
Write-Host "SHA-256: $EpSha256" -ForegroundColor Gray
