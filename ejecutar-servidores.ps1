# Script para ejecutar todos los servidores sin Docker
# Laravel + Python ML + Queue Worker + Vite

Write-Host "🚀 Iniciando todos los servidores (sin Docker)..." -ForegroundColor Green
Write-Host ""

# Refrescar PATH y agregar XAMPP si existe
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
if (Test-Path "C:\xampp\php\php.exe") {
    $env:Path = "C:\xampp\php;$env:Path"
}

# Directorio base del proyecto
$projectRoot = $PSScriptRoot
$laravelDir = Join-Path $projectRoot "tarea8"
$pythonMlDir = Join-Path $projectRoot "python-ml"

# Verificar que estamos en el directorio correcto
if (-not (Test-Path $laravelDir)) {
    Write-Host "❌ Error: No se encontró el directorio tarea8" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $pythonMlDir)) {
    Write-Host "❌ Error: No se encontró el directorio python-ml" -ForegroundColor Red
    exit 1
}

# Verificar dependencias PRIMERO
Write-Host "🔍 Verificando dependencias..." -ForegroundColor Cyan

# Verificar PHP
$phpFound = $false
try {
    $phpVersion = php --version 2>&1
    if ($phpVersion -match "PHP") {
        $phpFound = $true
        Write-Host "✓ PHP encontrado: $($phpVersion | Select-Object -First 1)" -ForegroundColor Green
    }
} catch {
    # Continuar para verificar otras ubicaciones
}

# Si no se encontró, intentar con XAMPP
if (-not $phpFound) {
    $xamppPhp = "C:\xampp\php\php.exe"
    if (Test-Path $xamppPhp) {
        $env:Path = "C:\xampp\php;$env:Path"
        $phpFound = $true
        $phpVersion = & $xamppPhp --version 2>&1 | Select-Object -First 1
        Write-Host "✓ PHP encontrado (XAMPP): $phpVersion" -ForegroundColor Green
    }
}

if (-not $phpFound) {
    Write-Host "❌ Error: PHP no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "   Instala PHP desde: https://windows.php.net/download/" -ForegroundColor Yellow
    Write-Host "   O asegúrate de que XAMPP esté instalado en C:\xampp" -ForegroundColor Yellow
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

# Verificar Python
try {
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python no encontrado"
    }
    Write-Host "✓ Python encontrado: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Python no está instalado o no está en el PATH" -ForegroundColor Red
    Write-Host "   Instala Python desde: https://www.python.org/downloads/" -ForegroundColor Yellow
    exit 1
}

# Verificar dependencias de Composer en Laravel
Write-Host "📦 Verificando dependencias de Composer..." -ForegroundColor Cyan
$autoloadPath = Join-Path $laravelDir "vendor\autoload.php"
if (-not (Test-Path $autoloadPath)) {
    Write-Host "⚠️  No se encontró el directorio vendor. Instalando dependencias de Composer..." -ForegroundColor Yellow
    
    # Verificar si existe composer.phar local
    $composerPhar = Join-Path $laravelDir "composer.phar"
    if (Test-Path $composerPhar) {
        Write-Host "   Usando composer.phar local..." -ForegroundColor Cyan
        Set-Location $laravelDir
        php composer.phar install --no-interaction --ignore-platform-reqs 2>&1 | Out-Null
    } else {
        # Intentar con composer global
        try {
            $composerCheck = composer --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   Usando Composer global..." -ForegroundColor Cyan
                Set-Location $laravelDir
                composer install --no-interaction --ignore-platform-reqs 2>&1 | Out-Null
            } else {
                throw "Composer no encontrado"
            }
        } catch {
            Write-Host "❌ Error: Composer no está instalado" -ForegroundColor Red
            Write-Host "   Opciones:" -ForegroundColor Yellow
            Write-Host "   1. Instala Composer desde: https://getcomposer.org/download/" -ForegroundColor Yellow
            Write-Host "   2. O descarga composer.phar en el directorio tarea8/" -ForegroundColor Yellow
            Write-Host "   3. O ejecuta: php -r `"copy('https://getcomposer.org/installer', 'composer-setup.php');`"" -ForegroundColor Yellow
            exit 1
        }
    }
    Write-Host "✓ Dependencias de Composer instaladas" -ForegroundColor Green
}

# Verificar dependencias de Node.js en Laravel
Write-Host "📦 Verificando dependencias de Node.js..." -ForegroundColor Cyan
$nodeModulesPath = Join-Path $laravelDir "node_modules"
if (-not (Test-Path $nodeModulesPath)) {
    Write-Host "⚠️  No se encontraron node_modules. Instalando dependencias..." -ForegroundColor Yellow
    Set-Location $laravelDir
    npm install
    Write-Host "✓ Dependencias de Node.js instaladas" -ForegroundColor Green
}

# Ahora configurar Laravel
Write-Host ""
Write-Host "🔍 Configurando Laravel..." -ForegroundColor Cyan

$envFile = Join-Path $laravelDir ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "⚠️  No se encontró archivo .env. Creando desde configuración por defecto..." -ForegroundColor Yellow
    
    # Crear .env básico (formato correcto sin caracteres especiales)
    $envContent = @"
APP_NAME="Sistema de Recomendaciones"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_TIMEZONE=UTC
APP_URL=http://localhost:8000

DB_CONNECTION=sqlite
DB_DATABASE=database/database.sqlite

PYTHON_ML_API_URL=http://localhost:5000

QUEUE_CONNECTION=database

SESSION_DRIVER=database
SESSION_LIFETIME=120

BROADCAST_CONNECTION=log
FILESYSTEM_DISK=local
LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=debug

VITE_APP_NAME="Sistema de Recomendaciones"
"@
    Set-Content -Path $envFile -Value $envContent
    Write-Host "✓ Archivo .env creado" -ForegroundColor Green
    
    # Generar APP_KEY
    Set-Location $laravelDir
    $phpExe = if (Test-Path "C:\xampp\php\php.exe") { "C:\xampp\php\php.exe" } else { "php" }
    & $phpExe artisan key:generate --quiet 2>&1 | Out-Null
    Write-Host "✓ Clave de aplicación generada" -ForegroundColor Green
}

# Verificar base de datos SQLite y migraciones
$dbPath = Join-Path $laravelDir "database\database.sqlite"
$dbDir = Join-Path $laravelDir "database"
if (-not (Test-Path $dbDir)) {
    New-Item -ItemType Directory -Path $dbDir -Force | Out-Null
}
if (-not (Test-Path $dbPath)) {
    Write-Host "⚠️  No se encontró la base de datos SQLite. Creando..." -ForegroundColor Yellow
    New-Item -ItemType File -Path $dbPath -Force | Out-Null
    Write-Host "✓ Base de datos SQLite creada" -ForegroundColor Green
}

# Verificar si las migraciones están ejecutadas (verificar si existe tabla cache)
Set-Location $laravelDir
$phpExe = if (Test-Path "C:\xampp\php\php.exe") { "C:\xampp\php\php.exe" } else { "php" }
$migrationsCheck = & $phpExe artisan migrate:status --quiet 2>&1
if ($LASTEXITCODE -ne 0 -or $migrationsCheck -match "not found" -or $migrationsCheck -match "No migrations") {
    Write-Host "📊 Ejecutando migraciones..." -ForegroundColor Yellow
    & $phpExe artisan migrate --force 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Migraciones ejecutadas" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Hubo un problema con las migraciones, pero continuando..." -ForegroundColor Yellow
    }
} else {
    Write-Host "✓ Base de datos verificada" -ForegroundColor Green
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
trap { Cleanup; break }

# ============================================
# 1. Iniciar Servidor Python ML (puerto 5000)
# ============================================
Write-Host "🐍 Iniciando servidor Python ML (http://localhost:5000)..." -ForegroundColor Cyan

# Verificar si existe el entorno virtual
$venvPath = Join-Path $pythonMlDir "venv"
if (-not (Test-Path $venvPath)) {
    Write-Host "⚠️  No se encontró el entorno virtual. Creando..." -ForegroundColor Yellow
    Set-Location $pythonMlDir
    python -m venv venv
    Write-Host "✓ Entorno virtual creado" -ForegroundColor Green
    
    Write-Host "📥 Instalando dependencias de Python..." -ForegroundColor Yellow
    & "$venvPath\Scripts\python.exe" -m pip install --upgrade pip
    & "$venvPath\Scripts\python.exe" -m pip install -r requirements.txt
    Write-Host "✓ Dependencias instaladas" -ForegroundColor Green
}

# Configurar variable de entorno para Python ML
$env:LARAVEL_API_URL = "http://localhost:8000"

Start-Job -Name "PythonML" -ScriptBlock {
    param($pythonMlDir, $venvPath)
    Set-Location $pythonMlDir
    $env:LARAVEL_API_URL = "http://localhost:8000"
    & "$venvPath\Scripts\python.exe" app.py
} -ArgumentList $pythonMlDir, $venvPath | Out-Null

# ============================================
# 2. Iniciar Servidor Laravel (puerto 8000)
# ============================================
Write-Host "🌐 Iniciando servidor Laravel (http://localhost:8000)..." -ForegroundColor Cyan

# Configurar variable de entorno para Laravel
$env:PYTHON_ML_API_URL = "http://localhost:5000"

Start-Job -Name "LaravelServer" -ScriptBlock {
    param($laravelDir, $phpPath)
    if ($phpPath -and (Test-Path $phpPath)) {
        $env:Path = "$phpPath;$env:Path"
    }
    Set-Location $laravelDir
    $env:PYTHON_ML_API_URL = "http://localhost:5000"
    & "$phpPath\php.exe" artisan serve
} -ArgumentList $laravelDir, "C:\xampp\php" | Out-Null

# ============================================
# 3. Iniciar Queue Worker de Laravel
# ============================================
Write-Host "📬 Iniciando queue worker de Laravel..." -ForegroundColor Cyan

Start-Job -Name "QueueWorker" -ScriptBlock {
    param($laravelDir, $phpPath)
    if ($phpPath -and (Test-Path $phpPath)) {
        $env:Path = "$phpPath;$env:Path"
    }
    Set-Location $laravelDir
    $env:PYTHON_ML_API_URL = "http://localhost:5000"
    & "$phpPath\php.exe" artisan queue:work --tries=3 --timeout=300
} -ArgumentList $laravelDir, "C:\xampp\php" | Out-Null

# ============================================
# 4. Iniciar Vite (desarrollo frontend)
# ============================================
Write-Host "⚡ Iniciando Vite (desarrollo frontend)..." -ForegroundColor Cyan

Start-Job -Name "Vite" -ScriptBlock {
    param($laravelDir)
    Set-Location $laravelDir
    npm run dev
} -ArgumentList $laravelDir | Out-Null

Write-Host ""
Write-Host "✅ Todos los servicios iniciados!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Servicios en ejecución:" -ForegroundColor Yellow
Write-Host "   • Python ML API: http://localhost:5000" -ForegroundColor White
Write-Host "   • Laravel: http://localhost:8000" -ForegroundColor White
Write-Host "   • Vite (HMR): http://localhost:5173" -ForegroundColor White
Write-Host "   • Queue Worker: Procesando jobs en segundo plano" -ForegroundColor White
Write-Host ""
Write-Host "💡 Presiona Ctrl+C para detener todos los servicios" -ForegroundColor Cyan
Write-Host ""

# Esperar un momento para que los servicios inicien
Start-Sleep -Seconds 3

# Mostrar logs de los trabajos
try {
    while ($true) {
        Start-Sleep -Seconds 2
        
        # Mostrar salida de Python ML
        $pythonOutput = Receive-Job -Name "PythonML" -ErrorAction SilentlyContinue
        if ($pythonOutput) {
            Write-Host "[Python ML] $pythonOutput" -ForegroundColor Green
        }
        
        # Mostrar salida de Laravel
        $laravelOutput = Receive-Job -Name "LaravelServer" -ErrorAction SilentlyContinue
        if ($laravelOutput) {
            Write-Host "[Laravel] $laravelOutput" -ForegroundColor Blue
        }
        
        # Mostrar salida de Queue Worker
        $queueOutput = Receive-Job -Name "QueueWorker" -ErrorAction SilentlyContinue
        if ($queueOutput) {
            Write-Host "[Queue] $queueOutput" -ForegroundColor Magenta
        }
        
        # Mostrar salida de Vite
        $viteOutput = Receive-Job -Name "Vite" -ErrorAction SilentlyContinue
        if ($viteOutput) {
            Write-Host "[Vite] $viteOutput" -ForegroundColor Cyan
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

