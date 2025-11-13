# 🐳 Guía de Docker para Sistema de Recomendaciones

Esta guía explica cómo usar Docker para ejecutar todo el sistema de recomendaciones con persistencia completa de datos.

## 📋 Requisitos Previos

- Docker Desktop instalado y ejecutándose
- Docker Compose v2.0 o superior

## 🚀 Inicio Rápido

### 1. Preparar el entorno

```bash
# Copiar archivo de configuración de ejemplo
cp docker-compose.override.yml.example docker-compose.override.yml
```

### 2. Inicializar el sistema

```bash
# Construir y levantar todos los servicios
docker-compose up -d --build

# Ejecutar migraciones y seeders
chmod +x docker-init.sh
./docker-init.sh
```

### 3. Acceder a la aplicación

- **Laravel (Nginx)**: http://localhost:8000
- **Vite (HMR)**: http://localhost:5173
- **Python ML API**: http://localhost:5000
- **MySQL**: localhost:3306

**Nota**: Todos los servicios se inician automáticamente, incluyendo:
- ✅ Queue Worker (para reentrenamiento)
- ✅ Scheduler (tareas programadas)
- ✅ Vite (hot reload frontend)

## 📦 Servicios Incluidos

### 1. MySQL (Base de Datos)
- **Puerto**: 3306
- **Base de datos**: `recommendation_db`
- **Usuario**: `laravel`
- **Contraseña**: `laravel_password`
- **Volumen persistente**: `mysql_data`

### 2. Laravel (Backend)
- **Servicio**: PHP-FPM
- **Volúmenes persistentes**:
  - `laravel_storage`: Archivos de storage
  - `laravel_bootstrap`: Cache de bootstrap

### 3. Nginx (Web Server)
- **Puerto**: 8000
- Sirve la aplicación Laravel

### 4. Python ML (Microservicio)
- **Puerto**: 5000
- **Volúmenes persistentes**:
  - `python_models`: Modelos entrenados (.pkl)
  - `python_data`: Datos de entrenamiento

### 5. Queue Worker
- Procesa jobs de Laravel en segundo plano
- Incluye el job de reentrenamiento
- **Se inicia automáticamente** al levantar Docker

### 6. Scheduler
- Ejecuta tareas programadas de Laravel
- **Se inicia automáticamente** al levantar Docker

### 7. Vite (Desarrollo Frontend)
- **Puerto**: 5173
- Hot Module Replacement (HMR) habilitado
- **Se inicia automáticamente** al levantar Docker
- Recarga automática de cambios en React/TypeScript

## 🔧 Comandos Útiles

### Gestión de Servicios

```bash
# Iniciar servicios
docker-compose up -d

# Detener servicios
docker-compose down

# Reiniciar servicios
docker-compose restart

# Ver logs
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f laravel
docker-compose logs -f python-ml
docker-compose logs -f queue
```

### Ejecutar Comandos en Contenedores

```bash
# Ejecutar artisan commands
docker-compose exec laravel php artisan migrate
docker-compose exec laravel php artisan db:seed
docker-compose exec laravel php artisan queue:work

# Acceder a shell de Laravel
docker-compose exec laravel bash

# Acceder a shell de Python ML
docker-compose exec python-ml bash

# Ver estado de la base de datos
docker-compose exec mysql mysql -u laravel -plaravel_password recommendation_db
```

### Gestión de Datos

```bash
# Backup de base de datos
docker-compose exec mysql mysqldump -u root -proot_password recommendation_db > backup.sql

# Restaurar base de datos
docker-compose exec -T mysql mysql -u root -proot_password recommendation_db < backup.sql

# Ver volúmenes
docker volume ls

# Inspeccionar un volumen
docker volume inspect tarea-08_mysql_data

# Eliminar todos los volúmenes (⚠️ CUIDADO: Elimina todos los datos)
docker-compose down -v
```

## 💾 Persistencia de Datos

Todos los datos importantes se almacenan en volúmenes Docker:

### Base de Datos
- **Volumen**: `mysql_data`
- **Ubicación**: `/var/lib/mysql` en el contenedor
- **Persiste**: Usuarios, items, interacciones, jobs, etc.

### Modelos de ML
- **Volumen**: `python_models`
- **Ubicación**: `/app/models` en el contenedor
- **Persiste**: Modelos entrenados (.pkl), cache de predicciones

### Datos de ML
- **Volumen**: `python_data`
- **Ubicación**: `/app/data` en el contenedor
- **Persiste**: Datos exportados de Laravel

### Storage de Laravel
- **Volumen**: `laravel_storage`
- **Ubicación**: `/var/www/html/storage` en el contenedor
- **Persiste**: Archivos subidos, exports, logs

### Cache de Bootstrap
- **Volumen**: `laravel_bootstrap`
- **Ubicación**: `/var/www/html/bootstrap/cache` en el contenedor
- **Persiste**: Cache de configuración

## 🔄 Reinicializar Sistema

Si necesitas reinicializar todo desde cero:

```bash
# Detener y eliminar contenedores y volúmenes
docker-compose down -v

# Reconstruir e iniciar
docker-compose up -d --build

# Ejecutar migraciones y seeders
./docker-init.sh
```

## 🐛 Solución de Problemas

### Los servicios no inician

```bash
# Verificar logs
docker-compose logs

# Verificar estado
docker-compose ps

# Reconstruir sin cache
docker-compose build --no-cache
```

### La base de datos no conecta

```bash
# Verificar que MySQL esté listo
docker-compose exec mysql mysqladmin ping -h localhost

# Verificar variables de entorno
docker-compose exec laravel env | grep DB_
```

### Los seeders no se ejecutan

```bash
# Ejecutar manualmente
docker-compose exec laravel php artisan db:seed --force

# Verificar que las tablas existan
docker-compose exec laravel php artisan migrate:status
```

### El queue worker no procesa jobs

```bash
# Ver logs del queue
docker-compose logs -f queue

# Reiniciar el queue worker
docker-compose restart queue
```

## 📝 Variables de Entorno

Las variables de entorno se pueden configurar en:
- `docker-compose.yml` (configuración base)
- `docker-compose.override.yml` (personalización local)

### Variables Importantes

```env
# Laravel
DB_CONNECTION=mysql
DB_HOST=mysql
DB_DATABASE=recommendation_db
DB_USERNAME=laravel
DB_PASSWORD=laravel_password
PYTHON_ML_API_URL=http://python-ml:5000
QUEUE_CONNECTION=database

# Python ML
LARAVEL_API_URL=http://nginx:80
```

## 🎯 Desarrollo vs Producción

### Desarrollo
- Usa `docker-compose.override.yml` para montar código local
- Hot reload habilitado
- Debug activado

### Producción
- No uses override files
- Construye imágenes optimizadas
- Usa variables de entorno seguras
- Configura SSL/TLS

## 📚 Recursos Adicionales

- [Documentación de Docker Compose](https://docs.docker.com/compose/)
- [Laravel Docker](https://laravel.com/docs/sail)
- [Flask Docker](https://flask.palletsprojects.com/en/latest/deploying/docker/)

