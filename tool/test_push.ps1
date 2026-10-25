# End-to-end push test: signs in with an e-mail/password account, asks the
# server to push a test notification to that account's phone, prints the result.
# Run from the project root:   . .\tool\test_push.ps1
$backend = 'https://ecopoint-api-2vey.onrender.com'
$opts = Get-Content 'lib\firebase_options.dart' -Raw
$apiKey = ([regex]"apiKey:\s*'([^']+)'").Match($opts).Groups[1].Value

function Show-HttpError($err) {
  $code = ''
  try { $code = [int]$err.Exception.Response.StatusCode } catch {}
  $body = ''
  try {
    $sr = New-Object IO.StreamReader($err.Exception.Response.GetResponseStream())
    $body = $sr.ReadToEnd()
  } catch {}
  Write-Host "HTTP $code $body" -ForegroundColor Red
  return $code
}

Write-Host "Server oyadilir (ilk sorgu 1 deqiqeye qeder cekebilir)..." -ForegroundColor Cyan
try { $h = Invoke-RestMethod "$backend/health" -TimeoutSec 120; Write-Host "Health: ok=$($h.ok)" } catch { Write-Host "Server cavab vermir." -ForegroundColor Red }

$email = Read-Host "Tetbiqde istifade etdiyin e-poct (Google yox, e-poct/parol hesabi)"
$sec   = Read-Host "Parol" -AsSecureString
$plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))

try {
  $login = Invoke-RestMethod -Method Post -TimeoutSec 60 `
    -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey" `
    -ContentType 'application/json' `
    -Body (@{ email = $email; password = $plain; returnSecureToken = $true } | ConvertTo-Json)
} catch {
  Write-Host "Giris alinmadi (e-poct/parol sehvdir?)" -ForegroundColor Red
  Show-HttpError $_ | Out-Null
  $login = $null
}
$plain = $null

if ($login) {
  try {
    $r = Invoke-RestMethod -Method Post -TimeoutSec 120 -Uri "$backend/api/sendTestPush" `
      -Headers @{ Authorization = "Bearer $($login.idToken)" } -ContentType 'application/json' -Body '{}'
    $x = $r.result
    Write-Host ""
    Write-Host "Qeydiyyatli telefon sayi : $($x.tokens)"
    Write-Host "FCM-e gonderilen        : $($x.sent)"
    Write-Host "Ugursuz                 : $($x.failed)"
    if ($x.errors -and $x.errors.Count -gt 0) { Write-Host "Xetalar: $($x.errors -join ' | ')" -ForegroundColor Yellow }
    if ($x.tokens -eq 0) {
      Write-Host "Telefon qeydiyyatdan kecmeyib: tetbiqi ac, bildiris icazesini ver, 1 deqiqe gozle." -ForegroundColor Yellow
    } elseif ($x.sent -gt 0) {
      Write-Host "Server push-u FCM-e verdi. Telefonda bildiris gorunmelidir (tetbiq arxa fonda olsun)." -ForegroundColor Green
    } else {
      Write-Host "FCM qebul etmedi: yuxaridaki xeta metnini mene yaz." -ForegroundColor Red
    }
  } catch {
    $c = Show-HttpError $_
    if ($c -eq 404) { Write-Host "Server hele yenilenmeyib: Render-de deploy bitene qeder 3-5 deqiqe gozle." -ForegroundColor Yellow }
  }
}
