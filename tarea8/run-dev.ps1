# Script alternativo para ejecutar Laravel sin Composer
# Ejecuta los servicios en paralelo usando PowerShell

Write-Host "🚀 Iniciando servicios de desarrollo Laravel..." -ForegroundColor Green

# Refrescar PATH para detectar PHP, Node.js, etc. (necesario en PowerShell)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Cambiar al directorio del proyecto
Set-Location $PSScriptRoot

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "artisan")) {
    Write-Host "❌ Error: No se encontró el archivo artisan. Asegúrate de estar en el directorio de Laravel." -ForegroundColor Red
    exit 1
}

# Verificar PHP
try {
    $phpVersion = php --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "PHP no encontrado"
    }
    Write-Host "✓ PHP encontrado" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: PHP no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "   Instala PHP desde: https://windows.php.net/download/" -ForegroundColor Yellow
    exit 1
}

# Verificar Node.js
try {
    $nodeVersion = node --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Node.js no encontrado"
    }
    Write-Host "✓ Node.js encontrado: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Node.js no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "   Instala Node.js desde: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Verificar npm
try {
    $npmVersion = npm --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "npm no encontrado"
    }
    Write-Host "✓ npm encontrado: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: npm no está disponible" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📦 Iniciando servicios..." -ForegroundColor Cyan
Write-Host ""

# Función para limpiar procesos al salir
function Cleanup {
    Write-Host ""
    Write-Host "🛑 Deteniendo servicios..." -ForegroundColor Yellow
    Get-Job | Stop-Job
    Get-Job | Remove-Job
    Write-Host "✓ Servicios detenidos" -ForegroundColor Green
}

# Registrar función de limpieza
Register-EngineEvent PowerShell.Exiting -Action { Cleanup } | Out-Null

# Iniciar servidor Laravel
Write-Host "🌐 Iniciando servidor Laravel (http://localhost:8000)..." -ForegroundColor Cyan
Start-Job -Name "LaravelServer" -ScriptBlock {
    Set-Location $using:PSScriptRoot
    php artisan serve
} | Out-Null

# Iniciar Vite (desarrollo frontend)
Write-Host "⚡ Iniciando Vite (desarrollo frontend)..." -ForegroundColor Cyan
Start-Job -Name "Vite" -ScriptBlock {
    Set-Location $using:PSScriptRoot
    npm run dev
} | Out-Null

# Opcional: Iniciar queue worker (descomenta si lo necesitas)
# Write-Host "📬 Iniciando queue worker..." -ForegroundColor Cyan
# Start-Job -Name "QueueWorker" -ScriptBlock {
#     Set-Location $using:PSScriptRoot
#     php artisan queue:listen --tries=1
# } | Out-Null

Write-Host ""
Write-Host "✅ Servicios iniciados!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Servicios en ejecución:" -ForegroundColor Yellow
Write-Host "   • Laravel: http://localhost:8000" -ForegroundColor White
Write-Host "   • Vite: http://localhost:5173 (puerto por defecto)" -ForegroundColor White
Write-Host ""
Write-Host "💡 Presiona Ctrl+C para detener todos los servicios" -ForegroundColor Cyan
Write-Host ""

# Mostrar logs de los trabajos
try {
    while ($true) {
        Start-Sleep -Seconds 2
        
        # Mostrar salida de Laravel
        $laravelOutput = Receive-Job -Name "LaravelServer" -ErrorAction SilentlyContinue
        if ($laravelOutput) {
            Write-Host "[Laravel] $laravelOutput" -ForegroundColor Blue
        }
        
        # Mostrar salida de Vite
        $viteOutput = Receive-Job -Name "Vite" -ErrorAction SilentlyContinue
        if ($viteOutput) {
            Write-Host "[Vite] $viteOutput" -ForegroundColor Magenta
        }
        
        # Verificar si los trabajos siguen activos
        $jobs = Get-Job | Where-Object { $_.State -eq "Running" }
        if ($jobs.Count -eq 0) {
            Write-Host "⚠️  Todos los servicios se han detenido" -ForegroundColor Yellow
            break
        }
    }
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
} finally {
    Cleanup
}

