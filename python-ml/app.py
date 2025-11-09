from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import pickle
import os
import numpy as np
from sklearn.decomposition import NMF
import requests
from datetime import datetime

app = Flask(__name__)
CORS(app)

# Configuración
MODEL_PATH = 'models/recommendation_model.pkl'
LARAVEL_API_URL = os.getenv('LARAVEL_API_URL', 'http://localhost:8000')
DATA_DIR = 'data'

# Crear directorios si no existen
os.makedirs('models', exist_ok=True)
os.makedirs(DATA_DIR, exist_ok=True)

def load_model():
    """Carga el modelo entrenado desde disco"""
    if os.path.exists(MODEL_PATH):
        with open(MODEL_PATH, 'rb') as f:
            return pickle.load(f)
    return None

def save_model(model):
    """Guarda el modelo entrenado en disco"""
    with open(MODEL_PATH, 'wb') as f:
        pickle.dump(model, f)

def fetch_interactions_from_laravel():
    """Obtiene las interacciones desde la API de Laravel"""
    url = f"{LARAVEL_API_URL}/api/interactions/export-json"
    print(f"Conectando a {url}...")
    
    try:
        # Usar timeout separado para conexión y lectura
        # (connect, read) = (5 segundos para conectar, 30 segundos para leer)
        response = requests.get(
            url,
            timeout=(5, 30),  # Timeout de conexión: 5s, timeout de lectura: 30s
            headers={
                'Accept': 'application/json',
                'User-Agent': 'Python-ML-Service/1.0'
            },
            stream=False  # No usar streaming para evitar problemas
        )
        
        print(f"✓ Respuesta recibida: Status {response.status_code}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"✓ Datos obtenidos exitosamente: {len(data)} interacciones")
                return data
            except ValueError as e:
                print(f"✗ Error al parsear JSON: {str(e)}")
                print(f"  Respuesta (primeros 200 chars): {response.text[:200]}")
                return []
        else:
            print(f"✗ Error HTTP {response.status_code}")
            print(f"  Respuesta: {response.text[:200]}")
            return []
            
    except requests.exceptions.Timeout as e:
        print(f"✗ Timeout: {str(e)}")
        print(f"  Laravel no respondió a tiempo. Verifica que esté corriendo.")
        return []
    except requests.exceptions.ConnectionError as e:
        print(f"✗ Error de conexión: {str(e)}")
        print(f"  No se pudo conectar con Laravel en {LARAVEL_API_URL}")
        print(f"  Asegúrate de que Laravel esté corriendo: php artisan serve")
        return []
    except requests.exceptions.RequestException as e:
        print(f"✗ Error en la petición: {str(e)}")
        return []
    except Exception as e:
        print(f"✗ Error inesperado: {type(e).__name__}: {str(e)}")
        import traceback
        print(traceback.format_exc())
        return []

def train_model(interactions_data):
    """Entrena el modelo de recomendación con los datos proporcionados"""
    if not interactions_data or len(interactions_data) == 0:
        raise ValueError("No hay datos de interacciones para entrenar")
    
    print(f"Procesando {len(interactions_data)} interacciones...")
    
    # Convertir a DataFrame
    df = pd.DataFrame(interactions_data)
    
    # Asegurar que tenemos las columnas necesarias
    required_columns = ['user_id', 'item_id', 'rating']
    if not all(col in df.columns for col in required_columns):
        raise ValueError(f"Faltan columnas requeridas: {required_columns}")
    
    # Limitar el tamaño de datos si es muy grande (para evitar cuelgues)
    MAX_INTERACTIONS = 10000
    if len(df) > MAX_INTERACTIONS:
        print(f"Advertencia: Limitando a {MAX_INTERACTIONS} interacciones para optimizar rendimiento")
        df = df.sample(n=MAX_INTERACTIONS, random_state=42).reset_index(drop=True)
    
    # Crear matriz usuario-item usando pivot (más eficiente)
    print("Construyendo matriz usuario-item...")
    R = df.pivot_table(
        index='user_id',
        columns='item_id',
        values='rating',
        fill_value=0,
        aggfunc='mean'
    )
    
    # Obtener IDs únicos
    user_ids = R.index.values
    item_ids = R.columns.values
    
    # Crear mapeos
    user_to_idx = {user_id: idx for idx, user_id in enumerate(user_ids)}
    item_to_idx = {item_id: idx for idx, item_id in enumerate(item_ids)}
    idx_to_user = {idx: user_id for user_id, idx in user_to_idx.items()}
    idx_to_item = {idx: item_id for item_id, idx in item_to_idx.items()}
    
    # Convertir a numpy array y usar float32 para ahorrar memoria
    R_array = R.values.astype(np.float32)
    n_users, n_items = R_array.shape
    
    print(f"Matriz: {n_users} usuarios x {n_items} items")
    
    # Normalizar ratings a escala 0-1 para NMF
    R_normalized = (R_array - 1) / 4.0  # Escalar de [1,5] a [0,1]
    R_normalized = np.clip(R_normalized, 0, 1)  # Asegurar rango válido
    
    # Calcular número de componentes (reducido para optimizar)
    # Usar máximo 15 componentes en lugar de 50
    max_components = min(15, min(n_users, n_items) - 1)
    if max_components < 1:
        max_components = 1
    
    print(f"Entrenando modelo NMF con {max_components} componentes...")
    
    # Entrenar modelo NMF con menos iteraciones y componentes
    model = NMF(
        n_components=max_components,
        random_state=42,
        max_iter=50,  # Reducido de 200 a 50
        alpha_W=0.01,  # Regularización para W (usuarios)
        alpha_H=0.01,  # Regularización para H (items)
        solver='cd',  # Coordinate descent es más rápido
        beta_loss='frobenius',
        init='random',
        verbose=0
    )
    
    W = model.fit_transform(R_normalized)  # Matriz de usuarios
    H = model.components_  # Matriz de items
    
    # Convertir a float32 para ahorrar memoria
    W = W.astype(np.float32)
    H = H.astype(np.float32)
    
    # Guardar información adicional necesaria para predicciones
    # NO guardar R_original para ahorrar memoria
    model_info = {
        'model': model,
        'W': W,
        'H': H,
        'user_to_idx': user_to_idx,
        'item_to_idx': item_to_idx,
        'idx_to_user': idx_to_user,
        'idx_to_item': idx_to_item,
        'user_ids': [int(uid) for uid in (user_ids.tolist() if hasattr(user_ids, 'tolist') else list(user_ids))],
        'item_ids': [int(iid) for iid in (item_ids.tolist() if hasattr(item_ids, 'tolist') else list(item_ids))],
    }
    
    # Calcular error de reconstrucción (opcional, para logging)
    R_pred = np.dot(W, H)
    mse = np.mean((R_normalized - R_pred) ** 2)
    print(f"Modelo entrenado - MSE: {mse:.4f}, Componentes: {max_components}, Usuarios: {n_users}, Items: {n_items}")
    
    # Limpiar memoria
    del R_array, R_normalized, R_pred, R
    
    return model_info

@app.route('/recommend', methods=['GET', 'POST'])
def recommend():
    """Endpoint para obtener recomendaciones para un usuario"""
    try:
        # Obtener user_id de la petición
        if request.method == 'GET':
            user_id = request.args.get('user_id', type=int)
        else:
            data = request.get_json()
            user_id = data.get('user_id')
        
        if user_id is None:
            return jsonify({'error': 'user_id es requerido'}), 400
        
        # Cargar modelo
        model_info = load_model()
        if model_info is None:
            return jsonify({
                'error': 'Modelo no entrenado. Por favor, ejecute /retrain primero.'
            }), 404
        
        # Verificar si el usuario está en el modelo
        if user_id not in model_info['user_to_idx']:
            return jsonify({
                'error': f'Usuario {user_id} no encontrado en el modelo'
            }), 404
        
        # Obtener todas las interacciones para saber qué items ya ha visto el usuario
        interactions = fetch_interactions_from_laravel()
        user_interactions = [i for i in interactions if i.get('user_id') == user_id]
        seen_items = set([i['item_id'] for i in user_interactions])
        
        # Obtener índice del usuario en el modelo
        user_idx = model_info['user_to_idx'][user_id]
        
        # Obtener vector de características del usuario (W[user_idx])
        user_vector = model_info['W'][user_idx]
        
        # Predecir ratings para todos los items: R_pred = W * H
        # Para este usuario: ratings_pred = user_vector * H
        ratings_pred = np.dot(user_vector, model_info['H'])
        
        # Convertir de vuelta a escala 1-5
        ratings_pred = (ratings_pred * 4.0) + 1
        ratings_pred = np.clip(ratings_pred, 1, 5)  # Asegurar que esté en rango [1,5]
        
        # Crear lista de predicciones (item_id, rating)
        predictions = []
        for item_idx, item_id in model_info['idx_to_item'].items():
            if item_id not in seen_items:  # Solo items no vistos
                # Convertir a tipos nativos de Python para JSON
                item_id_int = int(item_id) if hasattr(item_id, '__int__') else item_id
                rating_float = float(ratings_pred[item_idx])
                predictions.append((item_id_int, rating_float))
        
        if len(predictions) == 0:
            return jsonify({
                'message': 'No hay items nuevos para recomendar',
                'item_ids': []
            })
        
        # Ordenar por rating predicho (mayor a menor) y tomar los top 5
        predictions.sort(key=lambda x: x[1], reverse=True)
        top_items = [int(item_id) for item_id, rating in predictions[:5]]
        
        return jsonify({
            'user_id': int(user_id),
            'item_ids': top_items,
            'predictions': {str(int(item_id)): float(rating) for item_id, rating in predictions[:5]}
        })
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/retrain', methods=['POST'])
def retrain():
    """Endpoint para reentrenar el modelo con datos frescos"""
    try:
        print(f"[{datetime.now()}] Iniciando reentrenamiento del modelo...")
        
        # Obtener datos de Laravel
        print("Obteniendo datos de interacciones desde Laravel...")
        interactions_data = fetch_interactions_from_laravel()
        
        if not interactions_data or len(interactions_data) == 0:
            return jsonify({
                'error': 'No hay datos de interacciones disponibles',
                'message': 'Asegúrese de que haya interacciones registradas en Laravel'
            }), 400
        
        original_count = len(interactions_data)
        print(f"Se obtuvieron {original_count} interacciones")
        
        # Entrenar modelo
        print("Entrenando modelo...")
        model = train_model(interactions_data)
        
        # Guardar modelo
        print("Guardando modelo...")
        save_model(model)
        
        print(f"[{datetime.now()}] Reentrenamiento completado exitosamente")
        
        return jsonify({
            'message': 'Modelo reentrenado exitosamente',
            'interactions_count': original_count,
            'model_path': MODEL_PATH,
            'timestamp': datetime.now().isoformat()
        })
    
    except MemoryError:
        error_msg = "Error de memoria: Demasiados datos. Intente con menos interacciones."
        print(f"Error durante el reentrenamiento: {error_msg}")
        return jsonify({
            'error': 'Error al reentrenar el modelo',
            'details': error_msg
        }), 500
    except Exception as e:
        error_msg = str(e)
        print(f"Error durante el reentrenamiento: {error_msg}")
        return jsonify({
            'error': 'Error al reentrenar el modelo',
            'details': error_msg
        }), 500

@app.route('/health', methods=['GET'])
def health():
    """Endpoint de salud para verificar que el servicio está funcionando"""
    model_exists = os.path.exists(MODEL_PATH)
    return jsonify({
        'status': 'healthy',
        'model_loaded': model_exists,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/', methods=['GET'])
def index():
    """Endpoint raíz con información del servicio"""
    return jsonify({
        'service': 'ML Recommendation Service',
        'version': '1.0.0',
        'endpoints': {
            '/recommend': 'GET/POST - Obtener recomendaciones para un usuario',
            '/retrain': 'POST - Reentrenar el modelo',
            '/health': 'GET - Estado del servicio'
        }
    })

if __name__ == '__main__':
    # Si no existe un modelo, intentar entrenar uno inicial
    if not os.path.exists(MODEL_PATH):
        print("No se encontró modelo existente. Ejecute /retrain para entrenar uno inicial.")
    
    # Desactivar debug en producción para mejor rendimiento
    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)

