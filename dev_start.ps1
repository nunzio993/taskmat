$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

# 0. Pulizia Porte
$port = 3000
Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Where-Object { $_.OwningProcess -ne 0 } | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }

# 1. Avvia Docker
Set-Location "$ProjectRoot"
docker-compose -f infra/docker-compose.yml up -d db redis

# 2. Avvia Backend (Metodo Semplificato)
$backendPath = Join-Path $ProjectRoot "apps\backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; .\venv\Scripts\python.exe -m uvicorn main:app --reload --host 127.0.0.1 --port 8000"

# 3. Avvia Flutter
$env:Path += ";C:\src\flutter\bin"
Set-Location "$ProjectRoot\apps\mobile"
flutter run -d web-server --web-port 3000
