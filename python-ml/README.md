# Microservicio de Machine Learning - Sistema de Recomendación

Este microservicio proporciona un motor de recomendación basado en filtrado colaborativo usando la librería Surprise.

## Instalación

1. Crear un entorno virtual (recomendado):
```bash
python3 -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
```

2. Instalar dependencias:
```bash
pip install -r requirements.txt
```

## Configuración

El servicio se conecta a Laravel mediante la variable de entorno `LARAVEL_API_URL` (por defecto: `http://localhost:8000`).

Puedes configurarlo así:
```bash
export LARAVEL_API_URL=http://localhost:8000
```

## Ejecución

```bash
python app.py
```

El servicio estará disponible en `http://localhost:5000`

## Endpoints

### GET/POST `/recommend`
Obtiene recomendaciones para un usuario específico.

**Parámetros:**
- `user_id` (requerido): ID del usuario

**Ejemplo:**
```bash
curl http://localhost:5000/recommend?user_id=1
```

**Respuesta:**
```json
{
  "user_id": 1,
  "item_ids": [5, 8, 12, 15, 20],
  "predictions": {
    "5": 4.5,
    "8": 4.3,
    "12": 4.1,
    "15": 3.9,
    "20": 3.8
  }
}
```

### POST `/retrain`
Reentrena el modelo con datos frescos desde Laravel.

**Ejemplo:**
```bash
curl -X POST http://localhost:5000/retrain
```

**Respuesta:**
```json
{
  "message": "Modelo reentrenado exitosamente",
  "interactions_count": 150,
  "model_path": "models/recommendation_model.pkl",
  "timestamp": "2025-11-09T10:30:00"
}
```

### GET `/health`
Verifica el estado del servicio.

**Respuesta:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "timestamp": "2025-11-09T10:30:00"
}
```

## Algoritmo

El servicio utiliza **SVD (Singular Value Decomposition)** de la librería Surprise, que es una implementación eficiente de filtrado colaborativo basado en matrices.

## Modelo

El modelo entrenado se guarda en `models/recommendation_model.pkl` y se carga automáticamente al iniciar el servicio.

