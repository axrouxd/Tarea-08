import AppLayout from '@/layouts/app-layout';
import { type BreadcrumbItem } from '@/types';
import { Head, router } from '@inertiajs/react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { useState } from 'react';

const breadcrumbs: BreadcrumbItem[] = [
    {
        title: 'Items',
        href: '/items',
    },
];

interface Item {
    id: number;
    title: string;
    description: string | null;
    category: string | null;
    interactions?: Array<{
        id: number;
        rating: number;
    }>;
}

interface Props {
    items: Item[];
}

export default function ItemsIndex({ items }: Props) {
    const [ratings, setRatings] = useState<Record<number, number>>(
        items.reduce((acc, item) => {
            if (item.interactions && item.interactions.length > 0) {
                acc[item.id] = item.interactions[0].rating;
            }
            return acc;
        }, {} as Record<number, number>)
    );
    const [loading, setLoading] = useState<Record<number, boolean>>({});

    const getCsrfToken = (): string => {
        // Obtener el token CSRF del meta tag o cookie
        const metaTag = document.querySelector('meta[name="csrf-token"]');
        if (metaTag) {
            return metaTag.getAttribute('content') || '';
        }
        
        // Si no hay meta tag, intentar obtenerlo del cookie
        const cookies = document.cookie.split(';');
        for (const cookie of cookies) {
            const [name, value] = cookie.trim().split('=');
            if (name === 'XSRF-TOKEN') {
                return decodeURIComponent(value);
            }
        }
        
        return '';
    };

    const handleRating = async (itemId: number, rating: number) => {
        setRatings(prev => ({ ...prev, [itemId]: rating }));
        setLoading(prev => ({ ...prev, [itemId]: true }));

        try {
            const csrfToken = getCsrfToken();
            
            const response = await fetch('/interactions', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': csrfToken,
                },
                credentials: 'same-origin', // Incluir cookies
                body: JSON.stringify({
                    item_id: itemId,
                    rating: rating,
                    interaction_type: 'rating',
                }),
            });

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.message || 'Error al guardar interacción');
            }

            const data = await response.json();
            // La interacción se guardó exitosamente
            console.log('Interacción guardada:', data);
        } catch (error) {
            console.error('Error al guardar interacción:', error);
            // Revertir el rating si falla
            setRatings(prev => {
                const newRatings = { ...prev };
                delete newRatings[itemId];
                return newRatings;
            });
        } finally {
            setLoading(prev => ({ ...prev, [itemId]: false }));
        }
    };

    const renderStars = (itemId: number) => {
        const currentRating = ratings[itemId] || 0;
        return (
            <div className="flex gap-1">
                {[1, 2, 3, 4, 5].map((star) => (
                    <button
                        key={star}
                        onClick={() => handleRating(itemId, star)}
                        disabled={loading[itemId]}
                        className={`text-2xl transition-colors ${
                            star <= currentRating
                                ? 'text-yellow-400'
                                : 'text-gray-300 hover:text-yellow-200'
                        } ${loading[itemId] ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
                    >
                        ★
                    </button>
                ))}
            </div>
        );
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title="Items" />
            <div className="flex h-full flex-1 flex-col gap-4 overflow-x-auto rounded-xl p-4">
                <div className="flex items-center justify-between">
                    <h1 className="text-2xl font-bold">Items Disponibles</h1>
                    <Button
                        onClick={() => router.visit('/recommendations')}
                        variant="outline"
                    >
                        Ver Recomendaciones
                    </Button>
                </div>

                <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                    {items.map((item) => (
                        <Card key={item.id} className="p-4">
                            <div className="space-y-3">
                                <div>
                                    <h3 className="text-lg font-semibold">{item.title}</h3>
                                    {item.category && (
                                        <span className="text-sm text-muted-foreground">
                                            {item.category}
                                        </span>
                                    )}
                                </div>
                                
                                {item.description && (
                                    <p className="text-sm text-muted-foreground">
                                        {item.description}
                                    </p>
                                )}

                                <div className="space-y-2">
                                    <p className="text-sm font-medium">Calificación:</p>
                                    {renderStars(item.id)}
                                    {ratings[item.id] && (
                                        <p className="text-xs text-muted-foreground">
                                            Calificado: {ratings[item.id]}/5
                                        </p>
                                    )}
                                </div>
                            </div>
                        </Card>
                    ))}
                </div>

                {items.length === 0 && (
                    <div className="flex items-center justify-center py-12">
                        <p className="text-muted-foreground">No hay items disponibles</p>
                    </div>
                )}
            </div>
        </AppLayout>
    );
}

