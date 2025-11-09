<?php

use App\Http\Controllers\RecommendationController;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

// Tarea programada para reentrenar el modelo de recomendación
// Se ejecuta cada hora (puede cambiarse a daily() para ejecutar una vez al día)
Schedule::call(function () {
    $pythonApiUrl = env('PYTHON_ML_API_URL', 'http://localhost:5000');
    
    try {
        $response = \Illuminate\Support\Facades\Http::timeout(60)->post("{$pythonApiUrl}/retrain");
        
        if ($response->successful()) {
            \Illuminate\Support\Facades\Log::info('Modelo reentrenado exitosamente', [
                'data' => $response->json(),
            ]);
        } else {
            \Illuminate\Support\Facades\Log::error('Error al reentrenar el modelo', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
        }
    } catch (\Exception $e) {
        \Illuminate\Support\Facades\Log::error('Error al conectar con el servicio de ML', [
            'error' => $e->getMessage(),
        ]);
    }
})->hourly()
  ->name('retrain-recommendation-model')
  ->withoutOverlapping()
  ->onOneServer();
