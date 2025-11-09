<?php

namespace App\Http\Controllers;

use App\Models\Item;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Inertia\Inertia;

class RecommendationController extends Controller
{
    public function index()
    {
        $userId = Auth::id();
        
        // Llamar a la API de Python para obtener recomendaciones
        $pythonApiUrl = env('PYTHON_ML_API_URL', 'http://localhost:5000');
        
        try {
            $response = Http::timeout(10)->get("{$pythonApiUrl}/recommend", [
                'user_id' => $userId,
            ]);

            if ($response->successful()) {
                $recommendedItemIds = $response->json()['item_ids'] ?? [];
                
                $recommendedItems = Item::whereIn('id', $recommendedItemIds)
                    ->get()
                    ->sortBy(function ($item) use ($recommendedItemIds) {
                        return array_search($item->id, $recommendedItemIds);
                    })
                    ->values();

                return Inertia::render('Recommendations/Index', [
                    'recommendations' => $recommendedItems,
                ]);
            }
        } catch (\Exception $e) {
            // Si falla la conexión, mostrar mensaje de error
        }

        return Inertia::render('Recommendations/Index', [
            'recommendations' => collect([]),
            'error' => 'No se pudieron obtener recomendaciones en este momento.',
        ]);
    }

    public function triggerRetrain()
    {
        $pythonApiUrl = env('PYTHON_ML_API_URL', 'http://localhost:5000');
        
        try {
            $response = Http::timeout(60)->post("{$pythonApiUrl}/retrain");

            if ($response->successful()) {
                return response()->json([
                    'message' => 'Reentrenamiento iniciado exitosamente',
                    'data' => $response->json(),
                ]);
            }

            return response()->json([
                'message' => 'Error al iniciar el reentrenamiento',
                'error' => $response->body(),
            ], 500);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al conectar con el servicio de ML',
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
