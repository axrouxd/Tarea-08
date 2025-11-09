<?php

namespace Database\Seeders;

use App\Models\Interaction;
use App\Models\Item;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class InteractionSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $users = User::all();
        $items = Item::all();

        if ($users->isEmpty() || $items->isEmpty()) {
            $this->command->warn('No hay usuarios o items. Ejecute ItemSeeder primero.');
            return;
        }

        // Crear interacciones aleatorias para cada usuario
        foreach ($users as $user) {
            // Cada usuario interactúa con 3-8 items aleatorios
            $itemsToInteract = $items->random(rand(3, min(8, $items->count())));
            
            foreach ($itemsToInteract as $item) {
                Interaction::firstOrCreate(
                    [
                        'user_id' => $user->id,
                        'item_id' => $item->id,
                        'interaction_type' => 'rating',
                    ],
                    [
                        'rating' => rand(1, 5), // Rating aleatorio entre 1 y 5
                        'interaction_type' => 'rating',
                    ]
                );
            }
        }
    }
}
