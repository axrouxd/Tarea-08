# 🐍 Cómo Activar el Servicio Python ML

## Pasos Rápidos para Windows PowerShell

### 1. Navegar al directorio
```powershell
cd python-ml
```

### 2. Activar el entorno virtual
```powershell
venv\Scripts\Activate.ps1
```

> **Si obtienes un error de política de ejecución:**
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```
> Luego intenta activar nuevamente.

### 3. Ejecutar el servicio
```powershell
python app.py
```

### 4. Verificar que funciona
Abre otra terminal y prueba:
```powershell
curl http://localhost:5000/health
```

O visita en tu navegador: `http://localhost:5000`

---

## Comandos Completos (Primera Vez)

Si es la primera vez que ejecutas el servicio:

```powershell
# 1. Ir al directorio
cd python-ml

# 2. Crear entorno virtual (solo la primera vez)
python -m venv venv

# 3. Activar entorno virtual
venv\Scripts\Activate.ps1

# 4. Instalar dependencias (solo la primera vez)
pip install -r requirements.txt

# 5. Ejecutar el servicio
python app.py
```

---

## Comandos Completos (Siguientes Veces)

```powershell
cd python-ml
venv\Scripts\Activate.ps1
python app.py
```

---

## Verificar que el Servicio Está Corriendo

El servicio mostrará algo como:
```
⚠ No hay modelo. Ejecute POST /retrain para crear uno.
 * Running on http://0.0.0.0:5000
```

O si ya hay un modelo:
```
✓ Modelo encontrado. Listo para recomendar.
 * Running on http://0.0.0.0:5000
```

---

## Detener el Servicio

Presiona `Ctrl + C` en la terminal donde está corriendo.

---

## Solución de Problemas

### Error: "python no se reconoce como comando"
- Instala Python desde: https://www.python.org/downloads/
- Asegúrate de marcar "Add Python to PATH" durante la instalación

### Error: "venv no se reconoce"
- Asegúrate de estar en el directorio `python-ml`
- Verifica que el entorno virtual existe: `Test-Path venv`

### Error: "No se puede cargar el archivo porque la ejecución de scripts está deshabilitada"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Error: "ModuleNotFoundError"
```powershell
pip install -r requirements.txt
```

