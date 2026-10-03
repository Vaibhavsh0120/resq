param(
  [ValidateSet("chrome", "android")]
  [string]$Target = "chrome",
  [switch]$Seed
)

$ErrorActionPreference = "Stop"
$RepositoryRoot = Split-Path -Parent $PSScriptRoot
$FrontendRoot = Join-Path $RepositoryRoot "frontend"
$BackendRoot = Join-Path $RepositoryRoot "backend"

$localEnvironment = @{
  APP_ENV = "development"
  ALLOWED_ORIGINS = "http://localhost:5000,http://127.0.0.1:5000"
  FIREBASE_PROJECT_ID = "resq-106ed"
  FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099"
  FIRESTORE_EMULATOR_HOST = "127.0.0.1:8081"
}
$previousEnvironment = @{}
foreach ($name in $localEnvironment.Keys) {
  $previousEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, "Process")
  [Environment]::SetEnvironmentVariable($name, $localEnvironment[$name], "Process")
}
$firebase = $null
$backend = $null

function Wait-TcpPort([int]$Port, [string]$Name) {
  for ($attempt = 0; $attempt -lt 60; $attempt++) {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
      $task = $client.ConnectAsync("127.0.0.1", $Port)
      if ($task.Wait(500) -and $client.Connected) { return }
    } catch {
      # Keep waiting until the bounded startup window expires.
    } finally {
      $client.Dispose()
    }
    Start-Sleep -Milliseconds 500
  }
  throw "$Name did not start on port $Port within 30 seconds."
}

try {
  $firebase = Start-Process -FilePath "npx.cmd" -ArgumentList @(
    "--yes", "firebase-tools@15.30.1", "emulators:start",
    "--only", "auth,firestore", "--project", "resq-106ed"
  ) -WorkingDirectory $FrontendRoot -WindowStyle Hidden -PassThru

  $backend = Start-Process -FilePath "python.exe" -ArgumentList @(
    "-m", "uvicorn", "app.main:app", "--env-file", ".env.example",
    "--reload", "--host", "127.0.0.1", "--port", "8080"
  ) -WorkingDirectory $BackendRoot -WindowStyle Hidden -PassThru

  Wait-TcpPort -Port 8081 -Name "Firestore emulator"
  Wait-TcpPort -Port 9099 -Name "Auth emulator"
  Wait-TcpPort -Port 8080 -Name "FastAPI"
  if ($Seed) {
    & python (Join-Path $BackendRoot "scripts/seed_dev.py") --project resq-106ed
    if ($LASTEXITCODE -ne 0) { throw "Emulator seed failed." }
  }
  Push-Location $FrontendRoot
  try {
    if ($Target -eq "android") {
      & flutter run --dart-define-from-file=config/local.android.json
    } else {
      & flutter run -d chrome --web-port 5000 --dart-define-from-file=config/local.web.json
    }
    if ($LASTEXITCODE -ne 0) { throw "Flutter exited with code $LASTEXITCODE." }
  } finally {
    Pop-Location
  }
} finally {
  if ($backend) { Stop-Process -Id $backend.Id -Force -ErrorAction SilentlyContinue }
  if ($firebase) { Stop-Process -Id $firebase.Id -Force -ErrorAction SilentlyContinue }
  foreach ($name in $previousEnvironment.Keys) {
    if ($null -eq $previousEnvironment[$name]) {
      Remove-Item -LiteralPath ("Env:" + $name) -ErrorAction SilentlyContinue
    } else {
      [Environment]::SetEnvironmentVariable($name, $previousEnvironment[$name], "Process")
    }
  }
}
