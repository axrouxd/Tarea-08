import AppLayout from '@/layouts/app-layout';
import { type BreadcrumbItem } from '@/types';
import { Head, router } from '@inertiajs/react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { useState } from 'react';

const breadcrumbs: BreadcrumbItem[] = [
    {
        title: 'Recomendaciones',
        href: '/recommendations',
    },
];

interface Recommendation {
    id: number;
    title: string;
    description: string | null;
    category: string | null;
}

interface Props {
    recommendations: Recommendation[];
    error?: string;
}

export default function RecommendationsIndex({ recommendations, error }: Props) {
    const [retraining, setRetraining] = useState(false);

    const handleRetrain = async () => {
        setRetraining(true);
        try {
            const response = await fetch('/recommendations/retrain', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '',
                },
                credentials: 'same-origin',
            });

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.message || 'Error al reentrenar el modelo');
            }

            const data = await response.json();
            console.log('Modelo reentrenado:', data);
            
            // Recargar la página para mostrar las nuevas recomendaciones
            router.reload();
        } catch (error) {
            console.error('Error al reentrenar:', error);
            alert(error instanceof Error ? error.message : 'Error al reentrenar el modelo');
        } finally {
            setRetraining(false);
        }
    };

    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title="Recomendaciones" />
            <div className="flex h-full flex-1 flex-col gap-4 overflow-x-auto rounded-xl p-4">
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-2xl font-bold">Recomendaciones para Ti</h1>
                        <p className="text-sm text-muted-foreground">
                            Basado en tus interacciones y preferencias
                        </p>
                    </div>
                    <div className="flex gap-2">
                        <Button
                            onClick={() => router.visit('/items')}
                            variant="outline"
                        >
                            Ver Todos los Items
                        </Button>
                        <Button
                            onClick={handleRetrain}
                            disabled={retraining}
                            variant="secondary"
                        >
                            {retraining ? 'Reentrenando...' : 'Reentrenar Modelo'}
                        </Button>
                    </div>
                </div>

                {error && (
                    <Alert variant="destructive">
                        <AlertDescription>{error}</AlertDescription>
                    </Alert>
                )}

                {recommendations.length > 0 ? (
                    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                        {recommendations.map((item, index) => (
                            <Card key={item.id} className="p-4">
                                <div className="space-y-3">
                                    <div className="flex items-start justify-between">
                                        <div>
                                            <div className="flex items-center gap-2">
                                                <span className="flex h-6 w-6 items-center justify-center rounded-full bg-primary text-xs font-bold text-primary-foreground">
                                                    {index + 1}
                                                </span>
                                                <h3 className="text-lg font-semibold">{item.title}</h3>
                                            </div>
                                            {item.category && (
                                                <span className="text-sm text-muted-foreground">
                                                    {item.category}
                                                </span>
                                            )}
                                        </div>
                                    </div>
                                    
                                    {item.description && (
                                        <p className="text-sm text-muted-foreground">
                                            {item.description}
                                        </p>
                                    )}

                                    <Button
                                        onClick={() => router.visit('/items')}
                                        variant="outline"
                                        size="sm"
                                        className="w-full"
                                    >
                                        Ver Detalles
                                    </Button>
                                </div>
                            </Card>
                        ))}
                    </div>
                ) : (
                    <div className="flex flex-col items-center justify-center py-12 space-y-4">
                        <p className="text-muted-foreground text-center">
                            {error 
                                ? 'No se pudieron obtener recomendaciones en este momento.'
                                : 'Aún no hay recomendaciones disponibles. Interactúa con algunos items para obtener recomendaciones personalizadas.'}
                        </p>
                        <Button
                            onClick={() => router.visit('/items')}
                            variant="default"
                        >
                            Explorar Items
                        </Button>
                    </div>
                )}
            </div>
        </AppLayout>
    );
}

