# Script para instalar dependencias sin problemas de versión
Write-Host "🔧 Instalando dependencias..." -ForegroundColor Green

$laravelDir = Join-Path $PSScriptRoot "tarea8"
Set-Location $laravelDir

# Verificar PHP
$phpExe = if (Test-Path "C:\xampp\php\php.exe") { "C:\xampp\php\php.exe" } else { "php" }
$phpIni = if (Test-Path "C:\xampp\php\php.ini") { "C:\xampp\php\php.ini" } else { "" }

Write-Host "📦 Habilitando extensión zip de PHP..." -ForegroundColor Cyan

if ($phpIni -and (Test-Path $phpIni)) {
    $phpIniContent = Get-Content $phpIni -Raw
    if ($phpIniContent -notmatch ";extension=zip") {
        # Ya está habilitado o comentado diferente
        if ($phpIniContent -notmatch "extension=zip") {
            # Agregar extensión zip
            $phpIniContent = $phpIniContent + "`n; Habilitar extensión zip`nextension=zip`n"
            Set-Content -Path $phpIni -Value $phpIniContent -NoNewline
            Write-Host "✓ Extensión zip agregada a php.ini" -ForegroundColor Green
        } else {
            Write-Host "✓ Extensión zip ya está habilitada" -ForegroundColor Green
        }
    } else {
        # Descomentar
        $phpIniContent = $phpIniContent -replace ";extension=zip", "extension=zip"
        Set-Content -Path $phpIni -Value $phpIniContent -NoNewline
        Write-Host "✓ Extensión zip habilitada" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️  No se encontró php.ini, continuando..." -ForegroundColor Yellow
}

# Verificar Composer
Write-Host "`n📦 Instalando dependencias de Composer..." -ForegroundColor Cyan

$composerPhar = Join-Path $laravelDir "composer.phar"
if (-not (Test-Path $composerPhar)) {
    Write-Host "   Descargando Composer..." -ForegroundColor Yellow
    & $phpExe -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    & $phpExe composer-setup.php
    Remove-Item composer-setup.php -ErrorAction SilentlyContinue
}

Write-Host "   Instalando paquetes (esto puede tardar)..." -ForegroundColor Yellow
& $phpExe composer.phar install --ignore-platform-reqs --no-interaction

if (Test-Path "vendor\autoload.php") {
    Write-Host "`n✅ Dependencias instaladas correctamente!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Puede que falten algunas dependencias, pero continuando..." -ForegroundColor Yellow
}

Write-Host "`n💡 Ahora puedes ejecutar: .\ejecutar-servidores.ps1" -ForegroundColor Cyan

