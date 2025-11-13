# Sistema de Recomendación de Contenido Dinámico

Sistema completo de recomendación que integra Laravel 12 (frontend y backend) con un microservicio Python/Flask para Machine Learning.

## Estructura del Proyecto

```
Tarea_8/
├── tarea8/          # Aplicación Laravel 12
│   ├── app/
│   │   ├── Http/Controllers/
│   │   │   ├── InteractionController.php
│   │   │   └── RecommendationController.php
│   │   ├── Models/
│   │   │   ├── User.php
│   │   │   ├── Item.php
│   │   │   └── Interaction.php
│   │   └── Console/Commands/
│   │       └── ExportInteractions.php
│   ├── database/
│   │   ├── migrations/
│   │   └── seeders/
│   └── resources/js/pages/
│       ├── Items/Index.tsx
│       └── Recommendations/Index.tsx
└── python-ml/       # Microservicio Python/Flask
    ├── app.py
    ├── requirements.txt
    └── README.md
```

## Características

### Laravel (Backend y Frontend)
- ✅ Modelos: User, Item, Interaction
- ✅ Sistema de interacciones (ratings 1-5)
- ✅ Exportación de datos a CSV/JSON
- ✅ API para consumo de recomendaciones
- ✅ Interfaz de usuario con React/Inertia
- ✅ Scheduler automático para reentrenamiento

### Python/ML (Microservicio)
- ✅ API `/recommend` - Obtener recomendaciones
- ✅ API `/retrain` - Reentrenar modelo
- ✅ Algoritmo SVD (Filtrado Colaborativo)
- ✅ Persistencia de modelo con pickle

## Instalación

### Opción A: Docker (Recomendado) 🐳

La forma más fácil de ejecutar todo el sistema con persistencia completa de datos.

#### Requisitos
- Docker Desktop instalado y ejecutándose
- Docker Compose v2.0 o superior

#### Pasos

```bash
# 1. Construir y levantar todos los servicios
docker-compose up -d --build

# 2. Inicializar el sistema (migraciones y seeders)
# Windows PowerShell:
.\docker-init.ps1

# Linux/Mac:
chmod +x docker-init.sh
./docker-init.sh
```

#### Servicios Disponibles
- **Laravel (Nginx)**: http://localhost:8000
- **Vite (HMR)**: http://localhost:5173
- **Python ML API**: http://localhost:5000
- **MySQL**: localhost:3306

#### Servicios Automáticos (Iniciados con Docker)
- ✅ **Queue Worker**: Procesa jobs en segundo plano (reentrenamiento funcionará)
- ✅ **Scheduler**: Ejecuta tareas programadas
- ✅ **Vite**: Hot reload para desarrollo frontend

#### Credenciales por Defecto
- Email: `test@example.com`
- Password: `password`

#### Persistencia de Datos
Todos los datos se almacenan en volúmenes Docker:
- ✅ Base de datos (MySQL) - Usuarios, items, interacciones, jobs
- ✅ Modelos de ML entrenados - Modelos .pkl y cache
- ✅ Storage de Laravel - Archivos, logs, exports
- ✅ Logs y cache - Bootstrap cache, config cache

**Importante**: Al ejecutar `docker-init.ps1`, se ejecutan automáticamente:
- ✅ Migraciones de base de datos
- ✅ Seeders (72 items + interacciones)
- ✅ Queue worker activo
- ✅ Vite con hot reload
- ✅ Python ML listo para entrenar

Para más información, consulta [DOCKER.md](DOCKER.md)

---

### Opción B: Instalación Manual

### 1. Laravel

#### Si tienes Composer instalado:

```bash
cd tarea8
composer install
npm install
cp .env.example .env
php artisan key:generate
```

#### Si NO tienes Composer instalado:

```powershell
cd tarea8
.\instalar-dependencias.ps1
npm install
cp .env.example .env
php artisan key:generate
```

> **Nota:** El script `instalar-dependencias.ps1` descarga Composer automáticamente y lo usa para instalar las dependencias.

### 2. Configurar Base de Datos

Edita el archivo `.env`:

```env
DB_CONNECTION=sqlite
# O usa MySQL/PostgreSQL según prefieras

PYTHON_ML_API_URL=http://localhost:5000
```

### 3. Ejecutar Migraciones y Seeders

```bash
php artisan migrate
php artisan db:seed
```

### 4. Python/ML

```bash
cd python-ml
python -m venv venv

# Windows PowerShell:
venv\Scripts\Activate.ps1

# Windows CMD:
# venv\Scripts\activate.bat

# Linux/Mac:
# source venv/bin/activate

pip install -r requirements.txt
```

## Ejecución

### Laravel

#### Opción 1: Usando Composer (Recomendado)

```bash
cd tarea8
composer run dev
```

Este comando ejecuta automáticamente:
- Servidor Laravel (http://localhost:8000)
- Vite para desarrollo frontend
- Queue worker
- Logs en tiempo real

#### Opción 2: Script PowerShell (Sin Composer)

Si no tienes Composer instalado, puedes usar el script alternativo:

```powershell
cd tarea8
.\run-dev.ps1
```

#### Opción 3: Manual (Terminales Separadas)

```bash
# Terminal 1: Servidor Laravel
cd tarea8
php artisan serve

# Terminal 2: Vite (desarrollo frontend)
cd tarea8
npm run dev

# Terminal 3: Queue Worker (REQUERIDO para reentrenamiento asíncrono)
cd tarea8
php artisan queue:work

# Terminal 4: Scheduler (opcional, para tareas programadas)
cd tarea8
php artisan schedule:work
```

> **Nota:** Si `composer` no está disponible, consulta `tarea8/INSTALAR_COMPOSER.md` para instrucciones de instalación.

### Python/ML

#### Windows PowerShell:

```powershell
cd python-ml
venv\Scripts\Activate.ps1
python app.py
```

#### Windows CMD:

```cmd
cd python-ml
venv\Scripts\activate.bat
python app.py
```

#### Linux/Mac:

```bash
cd python-ml
source venv/bin/activate
python app.py
```

El servicio estará disponible en `http://localhost:5000`

> **Nota:** Si obtienes un error de política de ejecución en PowerShell, ejecuta:
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

## Uso

### 1. Entrenar el Modelo Inicial

Primero, necesitas entrenar el modelo con datos iniciales:

```bash
# Opción 1: Desde la API de Python
curl -X POST http://localhost:5000/retrain

# Opción 2: Desde Laravel (después de tener interacciones)
# El scheduler lo hará automáticamente cada hora
```

### 2. Obtener Recomendaciones

```bash
# Desde la API
curl "http://localhost:5000/recommend?user_id=1"

# Desde la interfaz web
# Navega a http://localhost:8000/recommendations
```

### 3. Registrar Interacciones

- Navega a `http://localhost:8000/items`
- Califica items con estrellas (1-5)
- Las interacciones se guardan automáticamente

### 4. Exportar Datos

```bash
# Comando Artisan
php artisan interactions:export --format=csv
php artisan interactions:export --format=json

# O desde la API
curl http://localhost:8000/api/interactions/export-json
```

## Rutas Principales

### Laravel
- `/dashboard` - Dashboard principal
- `/items` - Lista de items para calificar
- `/recommendations` - Recomendaciones personalizadas
- `/api/interactions/export-json` - Exportar interacciones (JSON)

### Python/ML
- `GET/POST /recommend?user_id=X` - Obtener recomendaciones
- `POST /retrain` - Reentrenar modelo
- `GET /health` - Estado del servicio

## Scheduler (Tareas Programadas)

El sistema incluye un scheduler que reentrena el modelo automáticamente cada hora. Para que funcione:

```bash
php artisan schedule:work
```

O configura un cron job en producción:

```bash
* * * * * cd /path-to-project/tarea8 && php artisan schedule:run >> /dev/null 2>&1
```

## Algoritmo de Recomendación

El sistema utiliza **SVD (Singular Value Decomposition)** de la librería Surprise, que es una implementación eficiente de filtrado colaborativo basado en matrices.

### Parámetros del Modelo
- `n_factors=50` - Número de factores latentes
- `n_epochs=20` - Iteraciones de entrenamiento
- `lr_all=0.005` - Tasa de aprendizaje
- `reg_all=0.02` - Regularización

## Estructura de Datos

### Interaction
- `user_id` - ID del usuario
- `item_id` - ID del item
- `rating` - Calificación (1-5)
- `interaction_type` - Tipo (rating, viewed, purchased)

### Item
- `title` - Título
- `description` - Descripción
- `category` - Categoría

## Troubleshooting

### El servicio Python no responde
1. Verifica que esté ejecutándose: `curl http://localhost:5000/health`
2. Revisa los logs del servicio
3. Verifica la variable `PYTHON_ML_API_URL` en `.env`

### No hay recomendaciones
1. Asegúrate de tener interacciones registradas
2. Entrena el modelo: `curl -X POST http://localhost:5000/retrain`
3. Verifica que el modelo se haya guardado en `python-ml/models/`

### Errores de CORS
El servicio Python ya incluye CORS habilitado. Si persisten problemas, verifica la configuración en `app.py`.

## Desarrollo

### Agregar más Items

Edita `database/seeders/ItemSeeder.php` o crea items desde la interfaz.

### Modificar el Algoritmo

Edita `python-ml/app.py`, función `train_model()`.

### Cambiar Frecuencia de Reentrenamiento

Edita `routes/console.php`, cambia `->hourly()` por `->daily()` u otra frecuencia.

## Notas

- El modelo se guarda en `python-ml/models/recommendation_model.pkl`
- Las exportaciones se guardan en `storage/app/exports/`
- El scheduler requiere que Laravel esté ejecutándose o un cron job configurado

