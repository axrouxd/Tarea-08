<?php

namespace App\Jobs;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class RetrainModelJob implements ShouldQueue
{
    use Queueable;

    /**
     * Parámetros opcionales para el reentrenamiento
     */
    public function __construct(
        public ?int $maxComponents = null,
        public ?int $maxIter = null,
    ) {
        //
    }

    /**
     * Execute the job.
     */
    public function handle(): void
    {
        $pythonApiUrl = env('PYTHON_ML_API_URL', 'http://localhost:5000');
        
        $payload = [];
        if ($this->maxComponents !== null) {
            $payload['max_components'] = $this->maxComponents;
        }
        if ($this->maxIter !== null) {
            $payload['max_iter'] = $this->maxIter;
        }
        
        try {
            Log::info('Iniciando reentrenamiento del modelo de ML', [
                'payload' => $payload,
                'python_api_url' => $pythonApiUrl,
            ]);

            // Timeout aumentado a 300s (5 minutos) para reentrenamiento
            $response = Http::timeout(300)->post("{$pythonApiUrl}/retrain", $payload);

            if ($response->successful()) {
                $responseData = $response->json();
                Log::info('Reentrenamiento completado exitosamente', [
                    'model_metadata' => $responseData['model_metadata'] ?? null,
                ]);
            } else {
                $errorData = $response->json();
                Log::error('Error en el reentrenamiento del modelo', [
                    'status' => $response->status(),
                    'error' => $errorData['error'] ?? $errorData['details'] ?? $response->body(),
                ]);
                throw new \Exception('Error al reentrenar el modelo: ' . ($errorData['error'] ?? 'Error desconocido'));
            }
        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            Log::error('Error de conexión al reentrenar el modelo', [
                'error' => $e->getMessage(),
            ]);
            throw new \Exception('No se pudo establecer conexión con el servicio de Python. Verifique que esté ejecutándose.');
        } catch (\Exception $e) {
            Log::error('Error inesperado al reentrenar el modelo', [
                'error' => $e->getMessage(),
            ]);
            throw $e;
        }
    }
}
