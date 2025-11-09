<?php

namespace Database\Seeders;

use App\Models\User;
// use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        User::firstOrCreate(
            ['email' => 'test@example.com'],
            [
                'name' => 'Test User',
                'password' => 'password',
                'email_verified_at' => now(),
            ]
        );

        // Crear algunos usuarios adicionales para tener más datos
        for ($i = 2; $i <= 5; $i++) {
            User::firstOrCreate(
                ['email' => "user{$i}@example.com"],
                [
                    'name' => "User {$i}",
                    'password' => 'password',
                    'email_verified_at' => now(),
                ]
            );
        }

        // Ejecutar seeders de Items e Interactions
        $this->call([
            ItemSeeder::class,
            InteractionSeeder::class,
        ]);
    }
}
