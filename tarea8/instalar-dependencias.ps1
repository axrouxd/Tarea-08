# Script para instalar dependencias de Laravel sin tener Composer instalado globalmente
# Descarga Composer PHAR y lo usa para instalar las dependencias

Write-Host "📦 Instalando dependencias de Laravel..." -ForegroundColor Green
Write-Host ""

# Refrescar PATH
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Cambiar al directorio del proyecto
Set-Location $PSScriptRoot

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "composer.json")) {
    Write-Host "❌ Error: No se encontró composer.json. Asegúrate de estar en el directorio de Laravel." -ForegroundColor Red
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

# Ruta donde guardar composer.phar
$composerPhar = Join-Path $PSScriptRoot "composer.phar"

# Verificar si ya existe composer.phar
if (Test-Path $composerPhar) {
    Write-Host "✓ Composer PHAR encontrado" -ForegroundColor Green
} else {
    Write-Host "📥 Descargando Composer PHAR..." -ForegroundColor Cyan
    try {
        $composerUrl = "https://getcomposer.org/download/latest-stable/composer.phar"
        Invoke-WebRequest -Uri $composerUrl -OutFile $composerPhar -UseBasicParsing
        Write-Host "✓ Composer PHAR descargado" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error al descargar Composer: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "💡 Solución alternativa:" -ForegroundColor Yellow
        Write-Host "   1. Descarga manualmente desde: https://getcomposer.org/download/" -ForegroundColor White
        Write-Host "   2. Guarda el archivo como 'composer.phar' en este directorio" -ForegroundColor White
        Write-Host "   3. Ejecuta este script nuevamente" -ForegroundColor White
        exit 1
    }
}

# Instalar dependencias
Write-Host ""
Write-Host "📦 Instalando dependencias con Composer..." -ForegroundColor Cyan
Write-Host "   (Esto puede tardar varios minutos la primera vez)" -ForegroundColor Yellow
Write-Host ""

try {
    # Intentar instalar sin dependencias de desarrollo primero (para PHP 8.2)
    Write-Host "   Intentando instalar dependencias de producción..." -ForegroundColor Yellow
    php composer.phar install --no-dev --no-interaction
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "✅ Dependencias de producción instaladas exitosamente!" -ForegroundColor Green
        Write-Host ""
        Write-Host "⚠️  Nota: Las dependencias de desarrollo (testing) requieren PHP 8.3+" -ForegroundColor Yellow
        Write-Host "   Para desarrollo, esto es suficiente. Para testing, actualiza a PHP 8.3+" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "💡 Ahora puedes ejecutar:" -ForegroundColor Cyan
        Write-Host "   .\run-dev.ps1" -ForegroundColor White
    } else {
        Write-Host ""
        Write-Host "⚠️  Error al instalar con --no-dev, intentando actualizar composer.lock..." -ForegroundColor Yellow
        Write-Host "   (Esto puede resolver problemas de compatibilidad)" -ForegroundColor Yellow
        php composer.phar update --no-dev --no-interaction
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "✅ Dependencias instaladas exitosamente!" -ForegroundColor Green
            Write-Host ""
            Write-Host "💡 Ahora puedes ejecutar:" -ForegroundColor Cyan
            Write-Host "   .\run-dev.ps1" -ForegroundColor White
        } else {
            Write-Host ""
            Write-Host "❌ Error al instalar dependencias" -ForegroundColor Red
            Write-Host ""
            Write-Host "💡 Soluciones:" -ForegroundColor Yellow
            Write-Host "   1. Actualiza PHP a versión 8.3 o superior" -ForegroundColor White
            Write-Host "   2. O ejecuta manualmente: php composer.phar install --no-dev" -ForegroundColor White
            exit 1
        }
    }
} catch {
    Write-Host ""
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}

