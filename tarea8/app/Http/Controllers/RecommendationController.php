<?php

namespace App\Http\Controllers;

use App\Jobs\RetrainModelJob;
use App\Models\Item;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Inertia\Inertia;

class RecommendationController extends Controller
{
    /**
     * Obtiene recomendaciones para el usuario autenticado
     * Ahora soporta el parámetro top_n (máximo 20 recomendaciones)
     */
    public function index(Request $request)
    {
        $userId = Auth::id();
        
        // Validar y obtener top_n (máximo 20 según las mejoras de Python)
        $topN = min((int) $request->get('top_n', 5), 20);
        
        // Llamar a la API de Python para obtener recomendaciones
        $pythonApiUrl = env('PYTHON_ML_API_URL', 'http://localhost:5000');
        
        try {
            // Timeout aumentado a 30s para mejor compatibilidad
            $response = Http::timeout(30)->get("{$pythonApiUrl}/recommend", [
                'user_id' => $userId,
                'top_n' => $topN,
            ]);

            if ($response->successful()) {
                $data = $response->json();
                $recommendedItemIds = $data['item_ids'] ?? [];
                
                $recommendedItems = Item::whereIn('id', $recommendedItemIds)
                    ->get()
                    ->sortBy(function ($item) use ($recommendedItemIds) {
                        return array_search($item->id, $recommendedItemIds);
                    })
                    ->values();

                return Inertia::render('Recommendations/Index', [
                    'recommendations' => $recommendedItems,
                    'metadata' => [
                        'total_available' => $data['total_available'] ?? 0,
                        'seen_items_count' => $data['seen_items_count'] ?? 0,
                        'predictions' => $data['predictions'] ?? [],
                    ],
                ]);
            }

            // Manejo mejorado de errores HTTP
            $errorData = $response->json();
            $errorMessage = $errorData['error'] ?? 'Error desconocido al obtener recomendaciones';
            
            // Si el usuario no existe en el modelo, mostrar mensaje específico
            if ($response->status() === 404 && isset($errorData['available_users'])) {
                $errorMessage = 'Tu usuario aún no está en el modelo de recomendaciones. Por favor, realiza algunas interacciones primero.';
            }

            return Inertia::render('Recommendations/Index', [
                'recommendations' => collect([]),
                'error' => $errorMessage,
            ]);
        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            return Inertia::render('Recommendations/Index', [
                'recommendations' => collect([]),
                'error' => 'No se pudo conectar con el servicio de recomendaciones. Verifique que el servicio esté ejecutándose.',
            ]);
        } catch (\Exception $e) {
            return Inertia::render('Recommendations/Index', [
                'recommendations' => collect([]),
                'error' => 'Error inesperado: ' . $e->getMessage(),
            ]);
        }
    }

    /**
     * Reentrena el modelo de recomendaciones de forma asíncrona
     * Ahora acepta parámetros opcionales: max_components y max_iter
     */
    public function triggerRetrain(Request $request)
    {
        // Validar y obtener parámetros opcionales
        $validated = $request->validate([
            'max_components' => 'nullable|integer|min:1|max:50',
            'max_iter' => 'nullable|integer|min:1|max:100',
        ]);
        
        try {
            // Despachar el job de forma asíncrona
            RetrainModelJob::dispatch(
                maxComponents: $validated['max_components'] ?? null,
                maxIter: $validated['max_iter'] ?? null,
            );

            return response()->json([
                'message' => 'Reentrenamiento iniciado en segundo plano. El proceso puede tardar varios minutos.',
                'status' => 'queued',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al iniciar el reentrenamiento',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Obtiene estadísticas del modelo de recomendaciones
     * Utiliza el nuevo endpoint /stats de Python
     */
    public function getStats()
    {
        $pythonApiUrl = env('PYTHON_ML_API_URL', 'http://localhost:5000');
        
        try {
            $response = Http::timeout(10)->get("{$pythonApiUrl}/stats");

            if ($response->successful()) {
                return response()->json([
                    'success' => true,
                    'data' => $response->json(),
                ]);
            }

            return response()->json([
                'success' => false,
                'error' => $response->json()['error'] ?? 'Error al obtener estadísticas',
            ], $response->status());
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'error' => 'Error al conectar con el servicio de ML: ' . $e->getMessage(),
            ], 503);
        }
    }

    /**
     * Verifica el estado de salud del servicio de ML
     */
    public function health()
    {
        $pythonApiUrl = env('PYTHON_ML_API_URL', 'http://localhost:5000');
        
        try {
            $response = Http::timeout(5)->get("{$pythonApiUrl}/health");

            if ($response->successful()) {
                return response()->json([
                    'status' => 'healthy',
                    'service' => $response->json(),
                ]);
            }

            return response()->json([
                'status' => 'unhealthy',
                'error' => $response->body(),
            ], $response->status());
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'unreachable',
                'error' => $e->getMessage(),
            ], 503);
        }
    }
}
