# 🔧 Solución: PHP no se detecta en PowerShell

## Problema
PHP funciona en CMD pero no en PowerShell.

## Solución Rápida

### Opción 1: Refrescar PATH en PowerShell (Temporal)

Abre PowerShell y ejecuta:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
php -v
```

### Opción 2: Cerrar y Reabrir PowerShell

1. Cierra todas las ventanas de PowerShell
2. Abre una nueva ventana de PowerShell
3. Ejecuta: `php -v`

### Opción 3: Usar el Script Actualizado

El script `run-dev.ps1` ahora refresca el PATH automáticamente, así que puedes usarlo directamente:

```powershell
cd tarea8
.\run-dev.ps1
```

## Verificar que PHP está en el PATH

Ejecuta en PowerShell:

```powershell
[Environment]::GetEnvironmentVariable("Path", "User") -split ';' | Where-Object { $_ -like '*php*' }
```

Deberías ver algo como: `C:\xampp\php`

## Si PHP no está en el PATH

1. Abre "Variables de entorno" en Windows:
   - Presiona `Win + R`
   - Escribe: `sysdm.cpl`
   - Ve a la pestaña "Opciones avanzadas"
   - Click en "Variables de entorno"

2. En "Variables de usuario", busca "Path" y edítala

3. Agrega la ruta donde está PHP (ejemplo: `C:\xampp\php`)

4. Guarda y cierra todas las ventanas de PowerShell

5. Abre una nueva ventana de PowerShell y prueba: `php -v`

## Ubicación Común de PHP

Si instalaste XAMPP, PHP está normalmente en:
- `C:\xampp\php`

Si instalaste PHP manualmente, puede estar en:
- `C:\php`
- `C:\Program Files\PHP`

## Verificar Instalación de PHP

En CMD (que sí funciona):
```cmd
where php
```

Esto te mostrará la ruta exacta donde está PHP.

