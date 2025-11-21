# Script simple - Abre cada servicio en su propia ventana
# Ejecutar desde la raíz del proyecto (donde está este archivo)

$root = $PSScriptRoot

Write-Host "🚀 Iniciando servidores en ventanas separadas..." -ForegroundColor Green
Write-Host ""

# Python ML
Write-Host "🐍 Python ML (puerto 5000)" -ForegroundColor Cyan
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "cd '$root\python-ml'; if (Test-Path venv\Scripts\Activate.ps1) { . venv\Scripts\Activate.ps1 }; `$env:LARAVEL_API_URL='http://localhost:8000'; python app.py"

Start-Sleep -Seconds 1

# Laravel
Write-Host "🌐 Laravel (puerto 8000)" -ForegroundColor Cyan
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "cd '$root\tarea8'; `$env:PYTHON_ML_API_URL='http://localhost:5000'; php artisan serve"

Start-Sleep -Seconds 1

# Queue Worker
Write-Host "📬 Queue Worker" -ForegroundColor Cyan
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "cd '$root\tarea8'; `$env:PYTHON_ML_API_URL='http://localhost:5000'; php artisan queue:work --tries=3"

Start-Sleep -Seconds 1

# Vite
Write-Host "⚡ Vite (puerto 5173)" -ForegroundColor Cyan
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "cd '$root\tarea8'; npm run dev"

Write-Host ""
Write-Host "✅ Servicios iniciados" -ForegroundColor Green
Write-Host ""
Write-Host "📊 URLs:" -ForegroundColor Yellow
Write-Host "   http://localhost:5000 - Python ML" -ForegroundColor White
Write-Host "   http://localhost:8000 - Laravel" -ForegroundColor White
Write-Host "   http://localhost:5173 - Vite" -ForegroundColor White
Write-Host ""
Write-Host "💡 Cierra las ventanas para detener los servicios" -ForegroundColor Cyan

