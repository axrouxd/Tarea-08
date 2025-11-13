# Script para buscar PHP en Windows
# Ejecuta: .\buscar-php.ps1

Write-Host "🔍 Buscando instalaciones de PHP..." -ForegroundColor Cyan
Write-Host ""

$found = $false
$searchPaths = @(
    "C:\php",
    "C:\xampp\php",
    "C:\Program Files\PHP",
    "C:\Program Files (x86)\PHP",
    "$env:LOCALAPPDATA\Programs\PHP",
    "C:\laragon\bin\php",
    "C:\wamp64\bin\php",
    "C:\tools\php"
)

# Buscar también en subdirectorios comunes
$additionalSearches = @(
    (Get-ChildItem -Path "C:\laragon\bin\php" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName),
    (Get-ChildItem -Path "C:\wamp64\bin\php" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName),
    (Get-ChildItem -Path "C:\Program Files" -Filter "php*" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName),
    (Get-ChildItem -Path "C:\Program Files (x86)" -Filter "php*" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName)
)

$allPaths = $searchPaths + $additionalSearches | Where-Object { $_ -ne $null } | Select-Object -Unique

foreach ($path in $allPaths) {
    if (Test-Path $path) {
        $phpExe = Join-Path $path "php.exe"
        if (Test-Path $phpExe) {
            $found = $true
            Write-Host "✅ PHP encontrado en:" -ForegroundColor Green
            Write-Host "   $path" -ForegroundColor White
            Write-Host ""
            
            Write-Host "   Versión:" -ForegroundColor Yellow
            $version = & $phpExe --version 2>&1 | Select-Object -First 1
            Write-Host "   $version" -ForegroundColor White
            Write-Host ""
            
            Write-Host "   Para agregarlo al PATH (ejecuta como Administrador):" -ForegroundColor Cyan
            Write-Host "   [Environment]::SetEnvironmentVariable('Path', `$env:Path + ';$path', [EnvironmentVariableTarget]::Machine)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "   O usa temporalmente en esta sesión:" -ForegroundColor Cyan
            Write-Host "   `$env:PATH += ';$path'" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "   O usa la ruta completa:" -ForegroundColor Cyan
            Write-Host "   & '$phpExe' artisan serve" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "─" * 60 -ForegroundColor DarkGray
            Write-Host ""
        }
    }
}

if (-not $found) {
    Write-Host "❌ No se encontró PHP en las ubicaciones comunes." -ForegroundColor Red
    Write-Host ""
    Write-Host "Ubicaciones buscadas:" -ForegroundColor Yellow
    foreach ($path in $allPaths) {
        Write-Host "   • $path" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "💡 Soluciones:" -ForegroundColor Cyan
    Write-Host "   1. Instala PHP desde: https://windows.php.net/download/" -ForegroundColor White
    Write-Host "   2. O instala XAMPP desde: https://www.apachefriends.org/" -ForegroundColor White
    Write-Host "   3. O instala Laragon desde: https://laragon.org/" -ForegroundColor White
    Write-Host ""
    Write-Host "   Si ya lo instalaste, busca manualmente la carpeta 'php' y ejecuta:" -ForegroundColor Yellow
    Write-Host "   cd 'ruta\a\php'" -ForegroundColor Cyan
    Write-Host "   .\php.exe --version" -ForegroundColor Cyan
}

