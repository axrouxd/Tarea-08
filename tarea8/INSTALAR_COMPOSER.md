# Guía de Instalación de Composer en Windows

## Método 1: Instalador de Composer (Recomendado)

1. Descarga el instalador desde: https://getcomposer.org/download/
2. Ejecuta `Composer-Setup.exe`
3. Sigue el asistente de instalación
4. Reinicia PowerShell/Terminal
5. Verifica con: `composer --version`

## Método 2: Instalación Manual

1. Descarga `composer.phar` desde: https://getcomposer.org/download/
2. Colócalo en `C:\ProgramData\ComposerSetup\bin\`
3. Agrega esa ruta al PATH del sistema

## Método 3: Usar Chocolatey (si lo tienes instalado)

```powershell
choco install composer
```

## Verificar Instalación

```powershell
composer --version
```

## Después de Instalar Composer

```powershell
cd tarea8
composer install
composer run dev
```

