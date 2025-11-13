<?php

namespace Database\Seeders;

use App\Models\Item;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class ItemSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $items = [
            // Libros
            ['title' => 'El Señor de los Anillos', 'description' => 'Trilogía épica de fantasía', 'category' => 'Libros'],
            ['title' => 'Harry Potter y la Piedra Filosofal', 'description' => 'Primera novela de la serie', 'category' => 'Libros'],
            ['title' => '1984', 'description' => 'Novela distópica de George Orwell', 'category' => 'Libros'],
            ['title' => 'Cien años de soledad', 'description' => 'Obra maestra de Gabriel García Márquez', 'category' => 'Libros'],
            ['title' => 'El Código Da Vinci', 'description' => 'Thriller de Dan Brown', 'category' => 'Libros'],
            ['title' => 'El Hobbit', 'description' => 'Aventura épica de J.R.R. Tolkien', 'category' => 'Libros'],
            ['title' => 'Dune', 'description' => 'Ciencia ficción épica de Frank Herbert', 'category' => 'Libros'],
            ['title' => 'El Nombre del Viento', 'description' => 'Fantasía épica de Patrick Rothfuss', 'category' => 'Libros'],
            ['title' => 'Juego de Tronos', 'description' => 'Saga de fantasía de George R.R. Martin', 'category' => 'Libros'],
            ['title' => 'El Alquimista', 'description' => 'Novela filosófica de Paulo Coelho', 'category' => 'Libros'],
            ['title' => 'Crimen y Castigo', 'description' => 'Clásico de Fiódor Dostoyevski', 'category' => 'Libros'],
            ['title' => 'Orgullo y Prejuicio', 'description' => 'Novela romántica de Jane Austen', 'category' => 'Libros'],
            
            // Películas
            ['title' => 'Matrix', 'description' => 'Película de ciencia ficción', 'category' => 'Películas'],
            ['title' => 'Inception', 'description' => 'Thriller de ciencia ficción', 'category' => 'Películas'],
            ['title' => 'Interstellar', 'description' => 'Drama espacial', 'category' => 'Películas'],
            ['title' => 'The Dark Knight', 'description' => 'Película de superhéroes', 'category' => 'Películas'],
            ['title' => 'Pulp Fiction', 'description' => 'Película de Quentin Tarantino', 'category' => 'Películas'],
            ['title' => 'The Godfather', 'description' => 'Clásico del cine de gánsteres', 'category' => 'Películas'],
            ['title' => 'Fight Club', 'description' => 'Thriller psicológico', 'category' => 'Películas'],
            ['title' => 'Forrest Gump', 'description' => 'Drama histórico', 'category' => 'Películas'],
            ['title' => 'The Shawshank Redemption', 'description' => 'Drama carcelario', 'category' => 'Películas'],
            ['title' => 'Gladiator', 'description' => 'Película épica histórica', 'category' => 'Películas'],
            ['title' => 'Avatar', 'description' => 'Ciencia ficción épica', 'category' => 'Películas'],
            ['title' => 'Titanic', 'description' => 'Drama romántico', 'category' => 'Películas'],
            ['title' => 'The Avengers', 'description' => 'Película de superhéroes', 'category' => 'Películas'],
            ['title' => 'Blade Runner 2049', 'description' => 'Ciencia ficción neo-noir', 'category' => 'Películas'],
            ['title' => 'Parasite', 'description' => 'Thriller surcoreano', 'category' => 'Películas'],
            
            // Electrónica
            ['title' => 'iPhone 15 Pro', 'description' => 'Smartphone de última generación', 'category' => 'Electrónica'],
            ['title' => 'Samsung Galaxy S24', 'description' => 'Smartphone Android', 'category' => 'Electrónica'],
            ['title' => 'MacBook Pro', 'description' => 'Laptop profesional', 'category' => 'Electrónica'],
            ['title' => 'PlayStation 5', 'description' => 'Consola de videojuegos', 'category' => 'Electrónica'],
            ['title' => 'Xbox Series X', 'description' => 'Consola de videojuegos', 'category' => 'Electrónica'],
            ['title' => 'Nintendo Switch', 'description' => 'Consola híbrida portátil', 'category' => 'Electrónica'],
            ['title' => 'iPad Pro', 'description' => 'Tablet profesional', 'category' => 'Electrónica'],
            ['title' => 'AirPods Pro', 'description' => 'Auriculares inalámbricos', 'category' => 'Electrónica'],
            ['title' => 'Sony WH-1000XM5', 'description' => 'Auriculares con cancelación de ruido', 'category' => 'Electrónica'],
            ['title' => 'Apple Watch Series 9', 'description' => 'Smartwatch', 'category' => 'Electrónica'],
            ['title' => 'Samsung QLED TV', 'description' => 'Televisor 4K', 'category' => 'Electrónica'],
            ['title' => 'DJI Mavic 3', 'description' => 'Drone profesional', 'category' => 'Electrónica'],
            ['title' => 'GoPro Hero 12', 'description' => 'Cámara de acción', 'category' => 'Electrónica'],
            ['title' => 'Kindle Paperwhite', 'description' => 'Lector de libros electrónicos', 'category' => 'Electrónica'],
            
            // Videojuegos
            ['title' => 'The Legend of Zelda: Tears of the Kingdom', 'description' => 'Aventura épica', 'category' => 'Videojuegos'],
            ['title' => 'Elden Ring', 'description' => 'RPG de acción', 'category' => 'Videojuegos'],
            ['title' => 'God of War Ragnarök', 'description' => 'Aventura de acción', 'category' => 'Videojuegos'],
            ['title' => 'Cyberpunk 2077', 'description' => 'RPG de ciencia ficción', 'category' => 'Videojuegos'],
            ['title' => 'Baldur\'s Gate 3', 'description' => 'RPG táctico', 'category' => 'Videojuegos'],
            ['title' => 'The Witcher 3', 'description' => 'RPG de fantasía', 'category' => 'Videojuegos'],
            ['title' => 'Red Dead Redemption 2', 'description' => 'Aventura del oeste', 'category' => 'Videojuegos'],
            ['title' => 'Grand Theft Auto V', 'description' => 'Mundo abierto', 'category' => 'Videojuegos'],
            ['title' => 'Minecraft', 'description' => 'Sandbox creativo', 'category' => 'Videojuegos'],
            ['title' => 'Fortnite', 'description' => 'Battle Royale', 'category' => 'Videojuegos'],
            ['title' => 'Call of Duty: Modern Warfare', 'description' => 'Shooter en primera persona', 'category' => 'Videojuegos'],
            ['title' => 'FIFA 24', 'description' => 'Simulador de fútbol', 'category' => 'Videojuegos'],
            
            // Música
            ['title' => 'Abbey Road - The Beatles', 'description' => 'Álbum clásico de rock', 'category' => 'Música'],
            ['title' => 'Dark Side of the Moon - Pink Floyd', 'description' => 'Álbum de rock progresivo', 'category' => 'Música'],
            ['title' => 'Thriller - Michael Jackson', 'description' => 'Álbum de pop', 'category' => 'Música'],
            ['title' => 'Nevermind - Nirvana', 'description' => 'Álbum de grunge', 'category' => 'Música'],
            ['title' => 'The Wall - Pink Floyd', 'description' => 'Ópera rock', 'category' => 'Música'],
            ['title' => 'OK Computer - Radiohead', 'description' => 'Álbum de rock alternativo', 'category' => 'Música'],
            ['title' => 'Rumours - Fleetwood Mac', 'description' => 'Álbum de rock clásico', 'category' => 'Música'],
            ['title' => 'Hotel California - Eagles', 'description' => 'Álbum de rock', 'category' => 'Música'],
            
            // Ropa
            ['title' => 'Chaqueta de Cuero', 'description' => 'Chaqueta de cuero genuino', 'category' => 'Ropa'],
            ['title' => 'Zapatillas Nike Air Max', 'description' => 'Zapatillas deportivas', 'category' => 'Ropa'],
            ['title' => 'Jeans Levis 501', 'description' => 'Jeans clásicos', 'category' => 'Ropa'],
            ['title' => 'Camisa Formal', 'description' => 'Camisa de vestir', 'category' => 'Ropa'],
            ['title' => 'Abrigo de Invierno', 'description' => 'Abrigo cálido', 'category' => 'Ropa'],
            ['title' => 'Reloj Casio', 'description' => 'Reloj digital clásico', 'category' => 'Ropa'],
            
            // Deportes
            ['title' => 'Pelota de Fútbol', 'description' => 'Pelota oficial', 'category' => 'Deportes'],
            ['title' => 'Raqueta de Tenis', 'description' => 'Raqueta profesional', 'category' => 'Deportes'],
            ['title' => 'Bicicleta de Montaña', 'description' => 'Bicicleta todo terreno', 'category' => 'Deportes'],
            ['title' => 'Pesas Ajustables', 'description' => 'Set de pesas para gimnasio', 'category' => 'Deportes'],
            ['title' => 'Balón de Baloncesto', 'description' => 'Balón oficial NBA', 'category' => 'Deportes'],
        ];

        foreach ($items as $item) {
            Item::firstOrCreate(
                ['title' => $item['title']],
                $item
            );
        }
    }
}
