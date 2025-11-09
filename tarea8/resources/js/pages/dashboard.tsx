import { PlaceholderPattern } from '@/components/ui/placeholder-pattern';
import AppLayout from '@/layouts/app-layout';
import { dashboard } from '@/routes';
import { type BreadcrumbItem } from '@/types';
import { Head, router } from '@inertiajs/react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';

const breadcrumbs: BreadcrumbItem[] = [
    {
        title: 'Dashboard',
        href: dashboard().url,
    },
];

export default function Dashboard() {
    return (
        <AppLayout breadcrumbs={breadcrumbs}>
            <Head title="Dashboard" />
            <div className="flex h-full flex-1 flex-col gap-4 overflow-x-auto rounded-xl p-4">
                <div className="mb-4">
                    <h1 className="text-2xl font-bold mb-2">Sistema de Recomendación</h1>
                    <p className="text-muted-foreground">
                        Explora items y obtén recomendaciones personalizadas basadas en tus interacciones
                    </p>
                </div>

                <div className="grid gap-4 md:grid-cols-2">
                    <Card className="p-6">
                        <div className="space-y-4">
                            <div>
                                <h2 className="text-xl font-semibold mb-2">Explorar Items</h2>
                                <p className="text-sm text-muted-foreground mb-4">
                                    Descubre y califica diferentes items. Tus interacciones ayudan a mejorar las recomendaciones.
                                </p>
                                <Button
                                    onClick={() => router.visit('/items')}
                                    className="w-full"
                                >
                                    Ver Items
                                </Button>
                            </div>
                        </div>
                    </Card>

                    <Card className="p-6">
                        <div className="space-y-4">
                            <div>
                                <h2 className="text-xl font-semibold mb-2">Recomendaciones</h2>
                                <p className="text-sm text-muted-foreground mb-4">
                                    Obtén recomendaciones personalizadas basadas en tus preferencias y las de otros usuarios.
                                </p>
                                <Button
                                    onClick={() => router.visit('/recommendations')}
                                    variant="outline"
                                    className="w-full"
                                >
                                    Ver Recomendaciones
                                </Button>
                            </div>
                        </div>
                    </Card>
                </div>
            </div>
        </AppLayout>
    );
}
