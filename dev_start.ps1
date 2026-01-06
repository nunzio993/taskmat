$ProjectRoot = $PSScriptRoot

# 1. Avvia container Docker (db e redis)
Write-Host "Starting database containers..." -ForegroundColor Cyan
Set-Location "$ProjectRoot"
docker-compose -f infra/docker-compose.yml up -d db redis

# 2. Attendi che PostgreSQL sia pronto
Write-Host "Waiting for PostgreSQL..." -ForegroundColor Yellow
for ($i = 1; $i -le 20; $i++) {
    $result = docker exec infra-db-1 pg_isready -U user -d taskmate 2>$null
    if ($result -match "accepting") { 
        Write-Host "PostgreSQL ready!" -ForegroundColor Green
        break 
    }
    Start-Sleep -Seconds 1
}

# 3. Avvia Backend (locale)
Write-Host "Starting Backend..." -ForegroundColor Cyan
$backendPath = Join-Path $ProjectRoot "apps\backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; .\venv\Scripts\python.exe -m uvicorn main:app --reload --host 127.0.0.1 --port 8000"

Start-Sleep -Seconds 2

# 4. Avvia Admin Panel (Flutter Web)
Write-Host "Starting Admin Panel on port 3003..." -ForegroundColor Cyan
$adminPath = Join-Path $ProjectRoot "apps\admin"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$adminPath'; C:\src\flutter\bin\flutter.bat run -d web-server --web-port=3003"

# 5. Avvia Flutter Mobile App
Write-Host "Starting Flutter Mobile App on port 3002..." -ForegroundColor Cyan
Set-Location "$ProjectRoot\apps\mobile"
& "C:\src\flutter\bin\flutter.bat" run -d web-server --web-port=3002 --web-hostname=0.0.0.0
