FROM php:8.3-fpm

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    nodejs \
    npm \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Establecer directorio de trabajo
WORKDIR /var/www/html

# Copiar archivos de configuración primero (para cache de Docker)
COPY composer.json composer.lock ./
# Instalar dependencias de producción (ignorar lock file si hay incompatibilidades)
RUN composer install --no-dev --no-scripts --no-autoloader --ignore-platform-reqs || \
    (rm -f composer.lock && composer install --no-dev --no-scripts --no-autoloader)

# Copiar package files
COPY package*.json ./

# Copiar el resto de los archivos
COPY . .

# Completar instalación de Composer
RUN composer dump-autoload --optimize

# Instalar dependencias de Node.js (no construir assets aquí, Vite lo hará en desarrollo)
RUN npm install

# Configurar permisos
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Exponer puerto
EXPOSE 9000

CMD ["php-fpm"]

