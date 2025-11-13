from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import pickle
import os
import numpy as np
from sklearn.decomposition import NMF
import requests
from datetime import datetime
from functools import lru_cache
import time

app = Flask(__name__)
CORS(app)

# Configuración
MODEL_PATH = 'models/recommendation_model.pkl'
CACHE_PATH = 'models/predictions_cache.pkl'
LARAVEL_API_URL = os.getenv('LARAVEL_API_URL', 'http://localhost:8000')
DATA_DIR = 'data'

# Cache en memoria para evitar lecturas repetidas de disco
_model_cache = None
_model_cache_time = None
MODEL_CACHE_TTL = 3600  # 1 hora

# Crear directorios si no existen
os.makedirs('models', exist_ok=True)
os.makedirs(DATA_DIR, exist_ok=True)

def load_model():
    """Carga el modelo desde caché en memoria o disco"""
    global _model_cache, _model_cache_time
    
    # Verificar si tenemos caché válido en memoria
    if _model_cache is not None and _model_cache_time is not None:
        if time.time() - _model_cache_time < MODEL_CACHE_TTL:
            return _model_cache
    
    # Cargar desde disco
    if os.path.exists(MODEL_PATH):
        with open(MODEL_PATH, 'rb') as f:
            _model_cache = pickle.load(f)
            _model_cache_time = time.time()
            return _model_cache
    return None

def save_model(model):
    """Guarda el modelo y actualiza caché"""
    global _model_cache, _model_cache_time
    
    with open(MODEL_PATH, 'wb') as f:
        pickle.dump(model, f)
    
    # Actualizar caché en memoria
    _model_cache = model
    _model_cache_time = time.time()

def fetch_interactions_from_laravel(batch_size=1000, max_batches=10):
    """
    Obtiene interacciones desde Laravel con paginación para evitar sobrecarga
    
    Args:
        batch_size: Tamaño de cada lote
        max_batches: Número máximo de lotes a procesar
    """
    url = f"{LARAVEL_API_URL}/api/interactions/export-json"
    print(f"Conectando a {url}...")
    
    try:
        # Aumentar timeout y agregar parámetros de paginación si es posible
        response = requests.get(
            url,
            timeout=(10, 60),  # Más tiempo para conexiones lentas
            headers={
                'Accept': 'application/json',
                'User-Agent': 'Python-ML-Service/1.0'
            },
            stream=False
        )
        
        print(f"✓ Respuesta recibida: Status {response.status_code}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                total = len(data)
                
                # Limitar cantidad de datos procesados
                max_interactions = batch_size * max_batches
                if total > max_interactions:
                    print(f"⚠ Limitando de {total} a {max_interactions} interacciones")
                    # Tomar las más recientes si hay timestamp
                    if data and 'created_at' in data[0]:
                        data = sorted(data, key=lambda x: x.get('created_at', ''), reverse=True)
                    data = data[:max_interactions]
                
                print(f"✓ Datos obtenidos: {len(data)} interacciones")
                return data
            except ValueError as e:
                print(f"✗ Error al parsear JSON: {str(e)}")
                return []
        else:
            print(f"✗ Error HTTP {response.status_code}")
            return []
            
    except requests.exceptions.Timeout as e:
        print(f"✗ Timeout: {str(e)}")
        return []
    except requests.exceptions.ConnectionError as e:
        print(f"✗ Error de conexión: {str(e)}")
        return []
    except Exception as e:
        print(f"✗ Error inesperado: {type(e).__name__}: {str(e)}")
        return []

def train_model(interactions_data, max_components=10, max_iter=30):
    """
    Entrena modelo optimizado para laptops con recursos limitados
    
    Args:
        max_components: Número máximo de componentes latentes (reducido a 10)
        max_iter: Iteraciones máximas (reducido a 30)
    """
    if not interactions_data or len(interactions_data) == 0:
        raise ValueError("No hay datos de interacciones para entrenar")
    
    print(f"Procesando {len(interactions_data)} interacciones...")
    
    # Convertir a DataFrame
    df = pd.DataFrame(interactions_data)
    
    # Validar columnas
    required_columns = ['user_id', 'item_id', 'rating']
    if not all(col in df.columns for col in required_columns):
        raise ValueError(f"Faltan columnas requeridas: {required_columns}")
    
    # Limitar tamaño para laptops (reducido a 5000)
    MAX_INTERACTIONS = 5000
    if len(df) > MAX_INTERACTIONS:
        print(f"⚠ Limitando a {MAX_INTERACTIONS} interacciones para optimizar")
        df = df.sample(n=MAX_INTERACTIONS, random_state=42).reset_index(drop=True)
    
    # Matriz usuario-item
    print("Construyendo matriz usuario-item...")
    R = df.pivot_table(
        index='user_id',
        columns='item_id',
        values='rating',
        fill_value=0,
        aggfunc='mean'
    )
    
    # IDs y mapeos
    user_ids = R.index.values
    item_ids = R.columns.values
    
    user_to_idx = {user_id: idx for idx, user_id in enumerate(user_ids)}
    item_to_idx = {item_id: idx for idx, item_id in enumerate(item_ids)}
    idx_to_user = {idx: user_id for user_id, idx in user_to_idx.items()}
    idx_to_item = {idx: item_id for item_id, idx in item_to_idx.items()}
    
    # Convertir a float32 para ahorrar memoria
    R_array = R.values.astype(np.float32)
    n_users, n_items = R_array.shape
    
    print(f"Matriz: {n_users} usuarios x {n_items} items")
    
    # Normalizar a [0,1]
    R_normalized = (R_array - 1) / 4.0
    R_normalized = np.clip(R_normalized, 0, 1)
    
    # Componentes reducidos para laptops
    n_components = min(max_components, min(n_users, n_items) - 1)
    if n_components < 1:
        n_components = 1
    
    print(f"Entrenando NMF con {n_components} componentes, {max_iter} iteraciones...")
    
    # Modelo NMF optimizado
    model = NMF(
        n_components=n_components,
        random_state=42,
        max_iter=max_iter,  # Reducido
        alpha_W=0.02,  # Más regularización
        alpha_H=0.02,
        solver='cd',  # Más rápido
        beta_loss='frobenius',
        init='nndsvd',  # Mejor inicialización
        verbose=0
    )
    
    W = model.fit_transform(R_normalized)
    H = model.components_
    
    # Float32 para ahorrar memoria
    W = W.astype(np.float32)
    H = H.astype(np.float32)
    
    # Pre-calcular predicciones para caché
    print("Pre-calculando predicciones para caché...")
    R_pred = np.dot(W, H)
    R_pred = (R_pred * 4.0) + 1  # Escalar a [1,5]
    R_pred = np.clip(R_pred, 1, 5)
    
    # Guardar items vistos por usuario para filtrado rápido
    user_seen_items = {}
    for user_id in user_ids:
        user_items = df[df['user_id'] == user_id]['item_id'].tolist()
        user_seen_items[int(user_id)] = set(int(i) for i in user_items)
    
    model_info = {
        'W': W,
        'H': H,
        'predictions': R_pred.astype(np.float32),  # Caché de predicciones
        'user_to_idx': user_to_idx,
        'item_to_idx': item_to_idx,
        'idx_to_user': idx_to_user,
        'idx_to_item': idx_to_item,
        'user_ids': [int(uid) for uid in user_ids],
        'item_ids': [int(iid) for iid in item_ids],
        'user_seen_items': user_seen_items,  # Caché de items vistos
        'metadata': {
            'n_components': n_components,
            'n_users': n_users,
            'n_items': n_items,
            'trained_at': datetime.now().isoformat()
        }
    }
    
    # MSE para logging
    mse = np.mean((R_normalized - (R_pred - 1) / 4.0) ** 2)
    print(f"✓ Modelo entrenado - MSE: {mse:.4f}, Componentes: {n_components}")
    
    # Limpiar memoria
    del R_array, R_normalized, R, R_pred
    
    return model_info

@app.route('/recommend', methods=['GET', 'POST'])
def recommend():
    """Endpoint optimizado para obtener recomendaciones"""
    try:
        # Obtener user_id
        if request.method == 'GET':
            user_id = request.args.get('user_id', type=int)
            top_n = request.args.get('top_n', default=5, type=int)
        else:
            data = request.get_json()
            user_id = data.get('user_id')
            top_n = data.get('top_n', 5)
        
        if user_id is None:
            return jsonify({'error': 'user_id es requerido'}), 400
        
        top_n = min(top_n, 20)  # Máximo 20 recomendaciones
        
        # Cargar modelo (usa caché en memoria)
        model_info = load_model()
        if model_info is None:
            return jsonify({
                'error': 'Modelo no entrenado. Ejecute /retrain primero.'
            }), 404
        
        # Verificar usuario
        if user_id not in model_info['user_to_idx']:
            return jsonify({
                'error': f'Usuario {user_id} no encontrado en el modelo',
                'available_users': model_info['user_ids'][:10]  # Primeros 10
            }), 404
        
        # Obtener índice del usuario
        user_idx = model_info['user_to_idx'][user_id]
        
        # Usar predicciones pre-calculadas (MUCHO más rápido)
        user_predictions = model_info['predictions'][user_idx]
        
        # Obtener items ya vistos desde caché
        seen_items = model_info['user_seen_items'].get(user_id, set())
        
        # Crear lista de predicciones (solo items no vistos)
        predictions = []
        for item_idx, item_id in model_info['idx_to_item'].items():
            if item_id not in seen_items:
                predictions.append((int(item_id), float(user_predictions[item_idx])))
        
        if len(predictions) == 0:
            return jsonify({
                'message': 'No hay items nuevos para recomendar',
                'user_id': int(user_id),
                'item_ids': [],
                'seen_items_count': len(seen_items)
            })
        
        # Ordenar y tomar top N
        predictions.sort(key=lambda x: x[1], reverse=True)
        top_items = predictions[:top_n]
        
        return jsonify({
            'user_id': int(user_id),
            'item_ids': [item_id for item_id, _ in top_items],
            'predictions': {str(item_id): rating for item_id, rating in top_items},
            'total_available': len(predictions),
            'seen_items_count': len(seen_items)
        })
    
    except Exception as e:
        import traceback
        print(f"Error en /recommend: {traceback.format_exc()}")
        return jsonify({'error': str(e)}), 500

@app.route('/retrain', methods=['POST'])
def retrain():
    """Endpoint optimizado para reentrenar el modelo"""
    try:
        print(f"[{datetime.now()}] Iniciando reentrenamiento...")
        
        # Parámetros opcionales
        data = request.get_json() or {}
        max_components = data.get('max_components', 10)
        max_iter = data.get('max_iter', 30)
        
        # Obtener datos con límites
        print("Obteniendo datos desde Laravel...")
        interactions_data = fetch_interactions_from_laravel(
            batch_size=1000,
            max_batches=5  # Máximo 5000 interacciones
        )
        
        if not interactions_data:
            return jsonify({
                'error': 'No hay datos disponibles',
                'message': 'Verifique que Laravel esté corriendo y tenga interacciones'
            }), 400
        
        print(f"Entrenando con {len(interactions_data)} interacciones...")
        
        # Entrenar modelo optimizado
        model = train_model(
            interactions_data,
            max_components=max_components,
            max_iter=max_iter
        )
        
        # Guardar modelo
        save_model(model)
        
        print(f"[{datetime.now()}] ✓ Reentrenamiento completado")
        
        return jsonify({
            'message': 'Modelo reentrenado exitosamente',
            'interactions_count': len(interactions_data),
            'model_metadata': model['metadata'],
            'timestamp': datetime.now().isoformat()
        })
    
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        print(f"Error en /retrain: {error_trace}")
        return jsonify({
            'error': 'Error al reentrenar',
            'details': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health():
    """Endpoint de salud con información del modelo"""
    model_exists = os.path.exists(MODEL_PATH)
    model_info = load_model() if model_exists else None
    
    health_data = {
        'status': 'healthy',
        'model_loaded': model_exists,
        'timestamp': datetime.now().isoformat()
    }
    
    if model_info and 'metadata' in model_info:
        health_data['model_metadata'] = model_info['metadata']
    
    return jsonify(health_data)

@app.route('/stats', methods=['GET'])
def stats():
    """Endpoint para ver estadísticas del modelo"""
    model_info = load_model()
    if not model_info:
        return jsonify({'error': 'Modelo no cargado'}), 404
    
    return jsonify({
        'users': len(model_info['user_ids']),
        'items': len(model_info['item_ids']),
        'metadata': model_info.get('metadata', {}),
        'cache_status': 'active' if _model_cache else 'inactive'
    })

@app.route('/', methods=['GET'])
def index():
    """Endpoint raíz con información del servicio"""
    return jsonify({
        'service': 'ML Recommendation Service (Optimizado)',
        'version': '2.0.0',
        'endpoints': {
            '/recommend': 'GET/POST - Obtener recomendaciones (user_id, top_n)',
            '/retrain': 'POST - Reentrenar modelo (max_components, max_iter)',
            '/health': 'GET - Estado del servicio',
            '/stats': 'GET - Estadísticas del modelo'
        },
        'optimizations': [
            'Caché de predicciones pre-calculadas',
            'Caché de modelo en memoria',
            'Items vistos cacheados',
            'Componentes reducidos (10)',
            'Iteraciones reducidas (30)',
            'Límite de 5000 interacciones'
        ]
    })

if __name__ == '__main__':
    if not os.path.exists(MODEL_PATH):
        print("⚠ No hay modelo. Ejecute POST /retrain para crear uno.")
    else:
        print("✓ Modelo encontrado. Listo para recomendar.")
    
    # Producción optimizada
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)