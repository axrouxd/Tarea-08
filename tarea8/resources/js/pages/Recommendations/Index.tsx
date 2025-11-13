import AppLayout from '@/layouts/app-layout';
import { type BreadcrumbItem } from '@/types';
import { Head, router } from '@inertiajs/react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { CheckCircle2, XCircle } from 'lucide-react';
import { useState, useEffect } from 'react';

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
    const [successMessage, setSuccessMessage] = useState<string | null>(null);
    const [errorMessage, setErrorMessage] = useState<string | null>(null);
    const [pollingInterval, setPollingInterval] = useState<NodeJS.Timeout | null>(null);

    // Auto-ocultar mensajes después de 5 segundos
    useEffect(() => {
        if (successMessage) {
            const timer = setTimeout(() => setSuccessMessage(null), 5000);
            return () => clearTimeout(timer);
        }
    }, [successMessage]);

    useEffect(() => {
        if (errorMessage) {
            const timer = setTimeout(() => setErrorMessage(null), 5000);
            return () => clearTimeout(timer);
        }
    }, [errorMessage]);

    // Limpiar intervalo al desmontar el componente
    useEffect(() => {
        return () => {
            if (pollingInterval) {
                clearInterval(pollingInterval);
            }
        };
    }, [pollingInterval]);

    const handleRetrain = async () => {
        setRetraining(true);
        setSuccessMessage(null);
        setErrorMessage(null);
        
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
                throw new Error(errorData.message || errorData.error || 'Error al iniciar el reentrenamiento');
            }

            const data = await response.json();
            console.log('Reentrenamiento iniciado:', data);
            
            // Mostrar mensaje de éxito
            setSuccessMessage('Reentrenamiento iniciado. Esperando a que termine...');
            
            // El reentrenamiento tarda aproximadamente 3-5 segundos según los logs
            // Esperamos un tiempo razonable y luego recargamos las recomendaciones
            // Hacemos polling cada 2 segundos para verificar si el modelo se actualizó
            let attempts = 0;
            const maxAttempts = 20; // Máximo 40 segundos (20 intentos × 2 segundos)
            let lastTrainedAt: string | null = null;
            
            // Primero obtenemos el timestamp actual del modelo para comparar
            try {
                const initialStatsResponse = await fetch('/api/recommendations/stats');
                if (initialStatsResponse.ok) {
                    const initialStats = await initialStatsResponse.json();
                    lastTrainedAt = initialStats.data?.model_metadata?.trained_at || null;
                }
            } catch (e) {
                console.error('Error al obtener estado inicial:', e);
            }
            
            const checkJobStatus = setInterval(async () => {
                attempts++;
                
                try {
                    const statsResponse = await fetch('/api/recommendations/stats');
                    if (statsResponse.ok) {
                        const stats = await statsResponse.json();
                        const currentTrainedAt = stats.data?.model_metadata?.trained_at;
                        
                        // Si el timestamp cambió, significa que el modelo se reentrenó
                        if (currentTrainedAt && currentTrainedAt !== lastTrainedAt) {
                            clearInterval(checkJobStatus);
                            setPollingInterval(null);
                            setSuccessMessage('Reentrenamiento completado. Recargando recomendaciones...');
                            // Recargar las recomendaciones después de un breve delay
                            setTimeout(() => {
                                router.reload({ only: ['recommendations', 'error'] });
                            }, 1000);
                            setRetraining(false);
                            return;
                        }
                    }
                } catch (e) {
                    console.error('Error al verificar estado:', e);
                }
                
                // Si excedemos los intentos, recargar de todas formas
                if (attempts >= maxAttempts) {
                    clearInterval(checkJobStatus);
                    setPollingInterval(null);
                    setSuccessMessage('Reentrenamiento completado. Recargando recomendaciones...');
                    setTimeout(() => {
                        router.reload({ only: ['recommendations', 'error'] });
                    }, 1000);
                    setRetraining(false);
                }
            }, 2000); // Verificar cada 2 segundos
            
            // Guardar la referencia del intervalo para poder limpiarlo
            setPollingInterval(checkJobStatus);
            
        } catch (error) {
            console.error('Error al reentrenar:', error);
            setErrorMessage(error instanceof Error ? error.message : 'Error al iniciar el reentrenamiento');
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

                {successMessage && (
                    <Alert className="bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800">
                        <CheckCircle2 className="h-4 w-4 text-green-600 dark:text-green-400" />
                        <AlertDescription className="text-green-800 dark:text-green-200">
                            {successMessage}
                        </AlertDescription>
                    </Alert>
                )}

                {errorMessage && (
                    <Alert variant="destructive">
                        <XCircle className="h-4 w-4" />
                        <AlertDescription>{errorMessage}</AlertDescription>
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

