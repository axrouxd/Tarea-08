<?php

use App\Http\Controllers\InteractionController;
use App\Http\Controllers\RecommendationController;
use Illuminate\Support\Facades\Route;
use Inertia\Inertia;
use Laravel\Fortify\Features;

Route::get('/', function () {
    return Inertia::render('welcome', [
        'canRegister' => Features::enabled(Features::registration()),
    ]);
})->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::get('dashboard', function () {
        return Inertia::render('dashboard');
    })->name('dashboard');

    // Rutas de interacciones
    Route::get('items', [InteractionController::class, 'index'])->name('items.index');
    Route::post('interactions', [InteractionController::class, 'store'])->name('interactions.store');
    
    // Rutas de recomendaciones
    Route::get('recommendations', [RecommendationController::class, 'index'])->name('recommendations.index');
    Route::post('recommendations/retrain', [RecommendationController::class, 'triggerRetrain'])->name('recommendations.retrain');
});

// Rutas de API para exportación (pueden ser públicas o protegidas según necesidad)
Route::get('api/interactions/export', [InteractionController::class, 'export'])->name('api.interactions.export');
Route::get('api/interactions/export-json', [InteractionController::class, 'exportJson'])->name('api.interactions.export-json');

// Rutas de API para estadísticas y salud del servicio ML (accesibles públicamente para monitoreo)
Route::get('api/recommendations/stats', [RecommendationController::class, 'getStats'])->name('api.recommendations.stats');
Route::get('api/recommendations/health', [RecommendationController::class, 'health'])->name('api.recommendations.health');

require __DIR__.'/settings.php';
