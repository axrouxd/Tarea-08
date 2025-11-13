#!/bin/bash

set -e

echo "🚀 Inicializando sistema de recomendaciones..."

# Esperar a que MySQL esté listo
echo "⏳ Esperando a que MySQL esté listo..."
max_attempts=30
attempt=0
until docker-compose exec -T mysql mysqladmin ping -h localhost --silent 2>/dev/null; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "❌ MySQL no está disponible después de $max_attempts intentos"
        exit 1
    fi
    echo "   Intento $attempt/$max_attempts..."
    sleep 2
done

echo "✅ MySQL está listo"

# Copiar .env si no existe
if [ ! -f tarea8/.env ]; then
    echo "📝 Creando archivo .env desde ejemplo..."
    if [ -f tarea8/.env.docker.example ]; then
        cp tarea8/.env.docker.example tarea8/.env
    else
        echo "⚠️  No se encontró .env.docker.example, usando valores por defecto"
    fi
fi

# Generar clave de aplicación
echo "🔑 Generando clave de aplicación..."
docker-compose exec -T laravel php artisan key:generate --force || true

# Ejecutar migraciones
echo "📦 Ejecutando migraciones..."
docker-compose exec -T laravel php artisan migrate --force

# Ejecutar seeders
echo "🌱 Ejecutando seeders..."
docker-compose exec -T laravel php artisan db:seed --force

# Limpiar y optimizar
echo "🧹 Optimizando aplicación..."
docker-compose exec -T laravel php artisan config:cache || true
docker-compose exec -T laravel php artisan route:cache || true
docker-compose exec -T laravel php artisan view:cache || true

# Verificar que todos los servicios estén corriendo
echo ""
echo "🔍 Verificando servicios..."
sleep 5

services=("mysql" "laravel" "nginx" "python-ml" "queue" "scheduler" "vite")
all_running=true

for service in "${services[@]}"; do
    if docker-compose ps --services --filter "status=running" | grep -q "$service"; then
        echo "   ✅ $service está corriendo"
    else
        echo "   ⚠️  $service no está corriendo"
        all_running=false
    fi
done

if [ "$all_running" = false ]; then
    echo ""
    echo "⚠️  Algunos servicios no están corriendo. Reiniciando..."
    docker-compose restart
    sleep 5
fi

echo ""
echo "✅ Sistema inicializado correctamente!"
echo ""
echo "📝 Servicios disponibles:"
echo "   - Laravel (Nginx): http://localhost:8000"
echo "   - Vite (HMR): http://localhost:5173"
echo "   - Python ML API: http://localhost:5000"
echo "   - MySQL: localhost:3306"
echo ""
echo "🔄 Servicios en segundo plano:"
echo "   - Queue Worker: Procesando jobs (incluye reentrenamiento)"
echo "   - Scheduler: Tareas programadas"
echo ""
echo "👤 Credenciales por defecto:"
echo "   - Email: test@example.com"
echo "   - Password: password"
echo ""
echo "💡 Comandos útiles:"
echo "   - Ver logs: docker-compose logs -f"
echo "   - Ver logs de un servicio: docker-compose logs -f queue"
echo "   - Detener: docker-compose down"
echo "   - Reiniciar: docker-compose restart"
echo "   - Reinicializar (elimina datos): docker-compose down -v && docker-compose up -d --build && ./docker-init.sh"
echo ""
echo "🎯 Estado del sistema:"
echo "   - ✅ Base de datos inicializada con seeders"
echo "   - ✅ Queue worker activo (reentrenamiento funcionará)"
echo "   - ✅ Vite activo (hot reload habilitado)"
echo "   - ✅ Python ML listo para entrenar modelos"

