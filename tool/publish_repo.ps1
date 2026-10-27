# Mirrors this project into the GitHub repo clone and pushes it.
# Run from the project root:   . .\tool\publish_repo.ps1
# Optional commit text first:  $Msg = "Yeni mukafatlar"
$repoUrl = 'https://github.com/suleymanalizada27-wq/EcoPointApp.git'
$work = Join-Path $HOME 'Desktop\ecopoint_repo'
$src  = (Get-Location).Path
if (-not (Test-Path (Join-Path $src 'pubspec.yaml'))) {
  Write-Host "Proyekt kokunde deyilsen (pubspec.yaml yoxdur)." -ForegroundColor Red
} else {
  if (-not (Test-Path (Join-Path $work '.git'))) { git clone $repoUrl $work }
  Push-Location $work
  git pull --ff-only
  Pop-Location

  # Mirror (also removes files that no longer exist). .git is never touched;
  # build outputs, node_modules, compiled backend and secrets are left out.
  robocopy $src $work /MIR /NFL /NDL /NJH /NJS /NP `
    /XD '.git' 'build' '.dart_tool' '.idea' '.gradle' 'node_modules' (Join-Path $src 'firebase\functions\lib') `
    /XF 'local.properties' 'key.properties' '*.jks' '*.keystore' '.secret.local' '.env' '*adminsdk*.json' '*.iml' | Out-Null
  if ($LASTEXITCODE -ge 8) { Write-Host "Kopyalama xetasi ($LASTEXITCODE)" -ForegroundColor Red }

  Push-Location $work
  git config user.name  'suleymanalizada27-wq'
  git config user.email 'suleymanalizada27-wq@users.noreply.github.com'
  git add -A

  # Safety net: refuse to publish anything that looks like a secret.
  $names = git diff --cached --name-only
  $bad = $names | Select-String -Pattern 'adminsdk|\.secret|\.jks|\.keystore|key\.properties|\.env$'
  # The backend needs src/lib (an old ignore rule once hid it): refuse to push without it.
  $srcLib = git ls-files --cached --others --exclude-standard 'firebase/functions/src/lib'
  if (-not $srcLib) { Write-Host "DAYANDIM: firebase/functions/src/lib gorunmur (.gitignore?)" -ForegroundColor Red; git reset | Out-Null; Pop-Location; return }
  $needle = 'BEGIN PRIVATE ' + 'KEY'
  $key = git grep --cached -l $needle
  if ($bad -or $key) {
    Write-Host "DAYANDIM: gizli fayl ola biler:" -ForegroundColor Red
    $bad; $key
    git reset | Out-Null
  } else {
    $text = if ($Msg) { $Msg } else { 'Update from local project' }
    git commit -m $text
    git push origin HEAD
    Write-Host "GitHub-a gonderildi. Render avtomatik yeniden deploy edecek." -ForegroundColor Green
  }
  Pop-Location
}
