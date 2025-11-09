<?php

namespace App\Http\Controllers;

use App\Models\Interaction;
use App\Models\Item;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Inertia\Inertia;

class InteractionController extends Controller
{
    public function index()
    {
        $items = Item::with(['interactions' => function ($query) {
            $query->where('user_id', Auth::id());
        }])->get();

        return Inertia::render('Items/Index', [
            'items' => $items,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'item_id' => 'required|exists:items,id',
            'rating' => 'required|integer|min:1|max:5',
            'interaction_type' => 'nullable|string|in:rating,viewed,purchased',
        ]);

        $interaction = Interaction::updateOrCreate(
            [
                'user_id' => Auth::id(),
                'item_id' => $validated['item_id'],
                'interaction_type' => $validated['interaction_type'] ?? 'rating',
            ],
            [
                'rating' => $validated['rating'],
            ]
        );

        return response()->json([
            'message' => 'Interacción registrada exitosamente',
            'interaction' => $interaction,
        ]);
    }

    public function export()
    {
        $interactions = Interaction::with(['user', 'item'])->get();

        $csvData = [];
        $csvData[] = ['user_id', 'item_id', 'rating', 'interaction_type', 'created_at'];

        foreach ($interactions as $interaction) {
            $csvData[] = [
                $interaction->user_id,
                $interaction->item_id,
                $interaction->rating,
                $interaction->interaction_type,
                $interaction->created_at->toDateTimeString(),
            ];
        }

        $filename = storage_path('app/exports/interactions_' . date('Y-m-d_His') . '.csv');
        
        if (!file_exists(storage_path('app/exports'))) {
            mkdir(storage_path('app/exports'), 0755, true);
        }

        $file = fopen($filename, 'w');
        foreach ($csvData as $row) {
            fputcsv($file, $row);
        }
        fclose($file);

        return response()->json([
            'message' => 'Datos exportados exitosamente',
            'file' => $filename,
            'count' => count($interactions),
        ]);
    }

    public function exportJson()
    {
        $interactions = Interaction::with(['user', 'item'])->get();

        $data = $interactions->map(function ($interaction) {
            return [
                'user_id' => $interaction->user_id,
                'item_id' => $interaction->item_id,
                'rating' => $interaction->rating,
                'interaction_type' => $interaction->interaction_type,
                'created_at' => $interaction->created_at->toDateTimeString(),
            ];
        });

        return response()->json($data);
    }
}
