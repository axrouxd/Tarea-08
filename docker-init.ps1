# Script de inicialización para Windows PowerShell

Write-Host "🚀 Inicializando sistema de recomendaciones..." -ForegroundColor Green

# Esperar a que MySQL esté listo
Write-Host "⏳ Esperando a que MySQL esté listo..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0
$mysqlReady = $false

while ($attempt -lt $maxAttempts) {
    $attempt++
    try {
        $result = docker-compose exec -T mysql mysqladmin ping -h localhost 2>&1
        if ($LASTEXITCODE -eq 0) {
            $mysqlReady = $true
            break
        }
    } catch {
        # Continuar intentando
    }
    Write-Host "   Intento $attempt/$maxAttempts..." -ForegroundColor Gray
    Start-Sleep -Seconds 2
}

if (-not $mysqlReady) {
    Write-Host "❌ MySQL no está disponible después de $maxAttempts intentos" -ForegroundColor Red
    exit 1
}

Write-Host "✅ MySQL está listo" -ForegroundColor Green

# Copiar .env si no existe
if (-not (Test-Path "tarea8\.env")) {
    Write-Host "📝 Creando archivo .env desde ejemplo..." -ForegroundColor Yellow
    if (Test-Path "tarea8\.env.docker.example") {
        Copy-Item "tarea8\.env.docker.example" "tarea8\.env"
    } else {
        Write-Host "⚠️  No se encontró .env.docker.example, usando valores por defecto" -ForegroundColor Yellow
    }
}

# Generar clave de aplicación
Write-Host "🔑 Generando clave de aplicación..." -ForegroundColor Yellow
docker-compose exec -T laravel php artisan key:generate --force 2>&1 | Out-Null

# Ejecutar migraciones
Write-Host "📦 Ejecutando migraciones..." -ForegroundColor Yellow
docker-compose exec -T laravel php artisan migrate --force

# Ejecutar seeders
Write-Host "🌱 Ejecutando seeders..." -ForegroundColor Yellow
docker-compose exec -T laravel php artisan db:seed --force

# Limpiar y optimizar
Write-Host "🧹 Optimizando aplicación..." -ForegroundColor Yellow
docker-compose exec -T laravel php artisan config:cache 2>&1 | Out-Null
docker-compose exec -T laravel php artisan route:cache 2>&1 | Out-Null
docker-compose exec -T laravel php artisan view:cache 2>&1 | Out-Null

# Verificar que todos los servicios estén corriendo
Write-Host ""
Write-Host "🔍 Verificando servicios..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

$services = @("mysql", "laravel", "nginx", "python-ml", "queue", "scheduler", "vite")
$allRunning = $true

foreach ($service in $services) {
    $status = docker-compose ps --services --filter "status=running" | Select-String -Pattern $service
    if ($status) {
        Write-Host "   ✅ $service está corriendo" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  $service no está corriendo" -ForegroundColor Yellow
        $allRunning = $false
    }
}

if (-not $allRunning) {
    Write-Host ""
    Write-Host "⚠️  Algunos servicios no están corriendo. Reiniciando..." -ForegroundColor Yellow
    docker-compose restart
    Start-Sleep -Seconds 5
}

Write-Host ""
Write-Host "✅ Sistema inicializado correctamente!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Servicios disponibles:" -ForegroundColor Cyan
Write-Host "   - Laravel (Nginx): http://localhost:8000"
Write-Host "   - Vite (HMR): http://localhost:5173"
Write-Host "   - Python ML API: http://localhost:5000"
Write-Host "   - MySQL: localhost:3306"
Write-Host ""
Write-Host "🔄 Servicios en segundo plano:" -ForegroundColor Cyan
Write-Host "   - Queue Worker: Procesando jobs (incluye reentrenamiento)"
Write-Host "   - Scheduler: Tareas programadas"
Write-Host ""
Write-Host "👤 Credenciales por defecto:" -ForegroundColor Cyan
Write-Host "   - Email: test@example.com"
Write-Host "   - Password: password"
Write-Host ""
Write-Host "💡 Comandos útiles:" -ForegroundColor Cyan
Write-Host "   - Ver logs: docker-compose logs -f"
Write-Host "   - Ver logs de un servicio: docker-compose logs -f queue"
Write-Host "   - Detener: docker-compose down"
Write-Host "   - Reiniciar: docker-compose restart"
Write-Host "   - Reinicializar (elimina datos): docker-compose down -v; docker-compose up -d --build; .\docker-init.ps1"
Write-Host ""
Write-Host "🎯 Estado del sistema:" -ForegroundColor Cyan
Write-Host "   - ✅ Base de datos inicializada con seeders"
Write-Host "   - ✅ Queue worker activo (reentrenamiento funcionará)"
Write-Host "   - ✅ Vite activo (hot reload habilitado)"
Write-Host "   - ✅ Python ML listo para entrenar modelos"

