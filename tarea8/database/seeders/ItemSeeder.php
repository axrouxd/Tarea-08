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
            ['title' => 'El Señor de los Anillos', 'description' => 'Trilogía épica de fantasía', 'category' => 'Libros'],
            ['title' => 'Harry Potter y la Piedra Filosofal', 'description' => 'Primera novela de la serie', 'category' => 'Libros'],
            ['title' => '1984', 'description' => 'Novela distópica de George Orwell', 'category' => 'Libros'],
            ['title' => 'Cien años de soledad', 'description' => 'Obra maestra de Gabriel García Márquez', 'category' => 'Libros'],
            ['title' => 'El Código Da Vinci', 'description' => 'Thriller de Dan Brown', 'category' => 'Libros'],
            ['title' => 'Matrix', 'description' => 'Película de ciencia ficción', 'category' => 'Películas'],
            ['title' => 'Inception', 'description' => 'Thriller de ciencia ficción', 'category' => 'Películas'],
            ['title' => 'Interstellar', 'description' => 'Drama espacial', 'category' => 'Películas'],
            ['title' => 'The Dark Knight', 'description' => 'Película de superhéroes', 'category' => 'Películas'],
            ['title' => 'Pulp Fiction', 'description' => 'Película de Quentin Tarantino', 'category' => 'Películas'],
            ['title' => 'iPhone 15 Pro', 'description' => 'Smartphone de última generación', 'category' => 'Electrónica'],
            ['title' => 'Samsung Galaxy S24', 'description' => 'Smartphone Android', 'category' => 'Electrónica'],
            ['title' => 'MacBook Pro', 'description' => 'Laptop profesional', 'category' => 'Electrónica'],
            ['title' => 'PlayStation 5', 'description' => 'Consola de videojuegos', 'category' => 'Electrónica'],
            ['title' => 'Xbox Series X', 'description' => 'Consola de videojuegos', 'category' => 'Electrónica'],
        ];

        foreach ($items as $item) {
            Item::firstOrCreate(
                ['title' => $item['title']],
                $item
            );
        }
    }
}
