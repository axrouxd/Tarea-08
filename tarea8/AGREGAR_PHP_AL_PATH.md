# 🔧 Cómo Agregar PHP al PATH en Windows

## Problema
PHP está instalado pero no se reconoce en PowerShell/CMD porque no está en el PATH del sistema.

## Solución: Agregar PHP al PATH

### Método 1: Desde PowerShell (Temporal - Solo esta sesión)

```powershell
# Reemplaza esta ruta con la ubicación real de tu PHP
$phpPath = "C:\php"
$env:PATH += ";$phpPath"
php --version
```

### Método 2: Permanente (Recomendado)

#### Paso 1: Encontrar la ubicación de PHP

Ejecuta estos comandos en PowerShell para buscar PHP:

```powershell
# Buscar en ubicaciones comunes
Get-ChildItem -Path "C:\Program Files" -Filter "php*" -Directory -ErrorAction SilentlyContinue
Get-ChildItem -Path "C:\xampp" -Filter "php*" -Directory -ErrorAction SilentlyContinue
Get-ChildItem -Path "$env:LOCALAPPDATA\Programs" -Filter "php*" -Directory -ErrorAction SilentlyContinue
Get-ChildItem -Path "C:\" -Filter "php*" -Directory -ErrorAction SilentlyContinue -Depth 1
```

O busca manualmente en:
- `C:\php`
- `C:\xampp\php`
- `C:\Program Files\PHP`
- `C:\Program Files (x86)\PHP`
- `C:\laragon\bin\php\php-*` (si usas Laragon)
- `C:\wamp64\bin\php\php-*` (si usas WAMP)

#### Paso 2: Verificar que PHP funciona

Navega a la carpeta donde está PHP y ejecuta:

```powershell
cd "C:\ruta\a\tu\php"
.\php.exe --version
```

Si funciona, copia esa ruta completa (ejemplo: `C:\php` o `C:\xampp\php`)

#### Paso 3: Agregar al PATH del Sistema

**Opción A: Desde PowerShell (Como Administrador)**

```powershell
# Abre PowerShell como Administrador y ejecuta:
# Reemplaza "C:\php" con tu ruta real
$phpPath = "C:\php"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$phpPath", [EnvironmentVariableTarget]::Machine)

# Reinicia PowerShell para que tome efecto
```

**Opción B: Desde la Interfaz Gráfica**

1. Presiona `Win + R`
2. Escribe: `sysdm.cpl` y presiona Enter
3. Ve a la pestaña **"Opciones avanzadas"**
4. Haz clic en **"Variables de entorno"**
5. En **"Variables del sistema"**, selecciona **"Path"** y haz clic en **"Editar"**
6. Haz clic en **"Nuevo"**
7. Agrega la ruta de PHP (ejemplo: `C:\php`)
8. Haz clic en **"Aceptar"** en todas las ventanas
9. **Cierra y vuelve a abrir PowerShell/CMD**

#### Paso 4: Verificar

Cierra y abre una nueva terminal PowerShell, luego:

```powershell
php --version
```

Deberías ver algo como:
```
PHP 8.2.x (cli) (built: ...)
```

## Ubicaciones Comunes de PHP

### Si instalaste desde php.net:
- `C:\php`

### Si usas XAMPP:
- `C:\xampp\php`

### Si usas Laragon:
- `C:\laragon\bin\php\php-8.2.0\` (o la versión que tengas)

### Si usas WAMP:
- `C:\wamp64\bin\php\php8.2.0\` (o la versión que tengas)

## Script de Búsqueda Automática

Ejecuta este script para buscar PHP automáticamente:

```powershell
$searchPaths = @(
    "C:\php",
    "C:\xampp\php",
    "C:\Program Files\PHP",
    "C:\Program Files (x86)\PHP",
    "$env:LOCALAPPDATA\Programs\PHP",
    "C:\laragon\bin\php",
    "C:\wamp64\bin\php"
)

Write-Host "Buscando PHP..." -ForegroundColor Cyan
foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        $phpExe = Join-Path $path "php.exe"
        if (Test-Path $phpExe) {
            Write-Host "✓ PHP encontrado en: $path" -ForegroundColor Green
            Write-Host "  Versión: " -NoNewline
            & $phpExe --version | Select-Object -First 1
            Write-Host ""
            Write-Host "Para agregarlo al PATH, ejecuta:" -ForegroundColor Yellow
            Write-Host "[Environment]::SetEnvironmentVariable('Path', `$env:Path + ';$path', [EnvironmentVariableTarget]::Machine)" -ForegroundColor Cyan
        }
    }
}
```

## Solución Rápida: Usar Ruta Completa

Mientras agregas PHP al PATH, puedes usar la ruta completa:

```powershell
# Ejemplo con XAMPP
C:\xampp\php\php.exe artisan serve

# Ejemplo con PHP standalone
C:\php\php.exe artisan serve
```

O crear un alias temporal en PowerShell:

```powershell
Set-Alias php "C:\ruta\a\tu\php\php.exe"
php --version
```

## Verificar Instalación de Composer

Después de agregar PHP al PATH, también necesitarás Composer. Verifica:

```powershell
composer --version
```

Si no funciona, consulta `INSTALAR_COMPOSER.md`

