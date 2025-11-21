# Script para iniciar desde tarea8
# Va a la raíz y ejecuta el script principal

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
& "$root\iniciar-servidores.ps1"

