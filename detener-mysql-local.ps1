# Script para detener MySQL local en Windows

Write-Host "🔍 Buscando servicios de MySQL..." -ForegroundColor Yellow

# Buscar servicios de MySQL
$mysqlServices = Get-Service | Where-Object { $_.Name -like "*mysql*" -or $_.DisplayName -like "*mysql*" }

if ($mysqlServices.Count -eq 0) {
    Write-Host "   ℹ️  No se encontraron servicios de MySQL instalados" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💡 Si MySQL está corriendo como proceso, puedes:" -ForegroundColor Yellow
    Write-Host "   1. Buscar el proceso: Get-Process | Where-Object {`$_.ProcessName -like '*mysql*'}" -ForegroundColor Gray
    Write-Host "   2. O verificar el puerto: netstat -ano | findstr :3306" -ForegroundColor Gray
    exit 0
}

Write-Host ""
Write-Host "📋 Servicios de MySQL encontrados:" -ForegroundColor Cyan
foreach ($service in $mysqlServices) {
    $status = if ($service.Status -eq "Running") { "🟢 Corriendo" } else { "🔴 Detenido" }
    Write-Host "   - $($service.DisplayName) ($($service.Name)): $status" -ForegroundColor White
}

$runningServices = $mysqlServices | Where-Object { $_.Status -eq "Running" }

if ($runningServices.Count -eq 0) {
    Write-Host ""
    Write-Host "✅ No hay servicios de MySQL corriendo" -ForegroundColor Green
    exit 0
}

Write-Host ""
Write-Host "🛑 Deteniendo servicios de MySQL..." -ForegroundColor Yellow

foreach ($service in $runningServices) {
    try {
        Write-Host "   Deteniendo $($service.DisplayName)..." -ForegroundColor Gray
        Stop-Service -Name $service.Name -Force
        Write-Host "   ✅ $($service.DisplayName) detenido" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ Error al detener $($service.DisplayName): $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✅ Proceso completado" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Ahora puedes ejecutar: .\docker-init.ps1" -ForegroundColor Cyan

