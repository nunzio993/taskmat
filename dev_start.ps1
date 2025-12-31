$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

# 0. Pulizia Porte
$ports = 3000, 8000
$ports | ForEach-Object {
    $p = $_
    Get-NetTCPConnection -LocalPort $p -ErrorAction SilentlyContinue | Where-Object { $_.OwningProcess -ne 0 } | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
}

# 1. Avvia Docker
Set-Location "$ProjectRoot"
docker-compose -f infra/docker-compose.yml up -d db redis

# 2. Avvia Backend (Metodo Semplificato)
$backendPath = Join-Path $ProjectRoot "apps\backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; .\venv\Scripts\python.exe -m uvicorn main:app --reload --host 127.0.0.1 --port 8000"

# 3. Avvia Flutter
# Start Flutter (Frontend)
Write-Host "Starting Flutter..."
cd apps\mobile
Write-Host "Cleaning Flutter build..."
Start-Process "C:\src\flutter\bin\flutter.bat" -ArgumentList "clean" -NoNewWindow -Wait
Write-Host "Starting Flutter..."
Start-Process "C:\src\flutter\bin\flutter.bat" -ArgumentList "run -d web-server --web-port=3002 --web-hostname=0.0.0.0" -NoNewWindow -Wait
