<?php

namespace App\Console\Commands;

use App\Models\Interaction;
use Illuminate\Console\Command;

class ExportInteractions extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'interactions:export {--format=csv : Formato de exportación (csv o json)}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Exporta todas las interacciones a CSV o JSON';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $format = $this->option('format');
        $interactions = Interaction::all();

        if (!file_exists(storage_path('app/exports'))) {
            mkdir(storage_path('app/exports'), 0755, true);
        }

        $timestamp = date('Y-m-d_His');
        
        if ($format === 'json') {
            $filename = storage_path("app/exports/interactions_{$timestamp}.json");
            $data = $interactions->map(function ($interaction) {
                return [
                    'user_id' => $interaction->user_id,
                    'item_id' => $interaction->item_id,
                    'rating' => $interaction->rating,
                    'interaction_type' => $interaction->interaction_type,
                    'created_at' => $interaction->created_at->toDateTimeString(),
                ];
            });
            
            file_put_contents($filename, json_encode($data, JSON_PRETTY_PRINT));
            $this->info("Interacciones exportadas a JSON: {$filename}");
        } else {
            $filename = storage_path("app/exports/interactions_{$timestamp}.csv");
            $file = fopen($filename, 'w');
            
            // Headers
            fputcsv($file, ['user_id', 'item_id', 'rating', 'interaction_type', 'created_at']);
            
            // Data
            foreach ($interactions as $interaction) {
                fputcsv($file, [
                    $interaction->user_id,
                    $interaction->item_id,
                    $interaction->rating,
                    $interaction->interaction_type,
                    $interaction->created_at->toDateTimeString(),
                ]);
            }
            
            fclose($file);
            $this->info("Interacciones exportadas a CSV: {$filename}");
        }

        $this->info("Total de interacciones exportadas: " . $interactions->count());
        
        return Command::SUCCESS;
    }
}
