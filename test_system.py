#!/usr/bin/env python3
"""
Script de pruebas completo para el sistema de recomendación
Verifica todas las funcionalidades del sistema
"""
import requests
import json
import sys
from datetime import datetime

# Colores para output
GREEN = '\033[92m'
RED = '\033[91m'
YELLOW = '\033[93m'
BLUE = '\033[94m'
RESET = '\033[0m'

def print_success(msg):
    print(f"{GREEN}✓{RESET} {msg}")

def print_error(msg):
    print(f"{RED}✗{RESET} {msg}")

def print_warning(msg):
    print(f"{YELLOW}⚠{RESET} {msg}")

def print_info(msg):
    print(f"{BLUE}ℹ{RESET} {msg}")

def test_laravel_api():
    """Prueba la API de Laravel"""
    print("\n" + "="*60)
    print("PRUEBA 1: API de Laravel - Exportación de Interacciones")
    print("="*60)
    
    try:
        url = "http://localhost:8000/api/interactions/export-json"
        print_info(f"Conectando a {url}...")
        
        response = requests.get(url, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            print_success(f"API responde correctamente: {len(data)} interacciones")
            
            if len(data) > 0:
                print_info(f"Ejemplo de interacción: Usuario {data[0]['user_id']} -> Item {data[0]['item_id']} (Rating: {data[0]['rating']})")
                return True, data
            else:
                print_warning("No hay interacciones en la base de datos")
                return False, []
        else:
            print_error(f"Error HTTP {response.status_code}: {response.text[:200]}")
            return False, []
            
    except requests.exceptions.ConnectionError:
        print_error("No se pudo conectar con Laravel")
        print_warning("Asegúrate de que Laravel esté corriendo: php artisan serve")
        return False, []
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False, []

def test_python_service():
    """Prueba el servicio Python ML"""
    print("\n" + "="*60)
    print("PRUEBA 2: Servicio Python ML")
    print("="*60)
    
    # Test health endpoint
    try:
        response = requests.get("http://localhost:5000/health", timeout=5)
        if response.status_code == 200:
            health = response.json()
            print_success("Servicio Python está corriendo")
            print_info(f"Estado: {health.get('status', 'unknown')}")
            print_info(f"Modelo cargado: {health.get('model_loaded', False)}")
            return True
        else:
            print_error(f"Error en health check: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print_error("Servicio Python no está corriendo")
        print_warning("Inicia el servicio: cd python-ml && source venv/bin/activate && python app.py")
        return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

def test_retrain():
    """Prueba el reentrenamiento del modelo"""
    print("\n" + "="*60)
    print("PRUEBA 3: Reentrenamiento del Modelo")
    print("="*60)
    
    try:
        print_info("Iniciando reentrenamiento...")
        response = requests.post(
            "http://localhost:5000/retrain",
            timeout=120  # 2 minutos para el entrenamiento
        )
        
        if response.status_code == 200:
            data = response.json()
            print_success("Reentrenamiento completado exitosamente")
            print_info(f"Interacciones procesadas: {data.get('interactions_count', 'N/A')}")
            print_info(f"Modelo guardado en: {data.get('model_path', 'N/A')}")
            return True
        else:
            error_data = response.json() if response.headers.get('content-type', '').startswith('application/json') else {}
            print_error(f"Error en reentrenamiento: {response.status_code}")
            print_error(f"Detalles: {error_data.get('error', response.text[:200])}")
            return False
            
    except requests.exceptions.Timeout:
        print_error("Timeout: El reentrenamiento tardó más de 2 minutos")
        return False
    except requests.exceptions.ConnectionError:
        print_error("No se pudo conectar con el servicio Python")
        return False
    except Exception as e:
        print_error(f"Error: {str(e)}")
        return False

def test_recommendations():
    """Prueba obtener recomendaciones"""
    print("\n" + "="*60)
    print("PRUEBA 4: Obtener Recomendaciones")
    print("="*60)
    
    # Probar con diferentes usuarios
    test_users = [1, 2, 6]
    
    for user_id in test_users:
        try:
            print_info(f"Probando recomendaciones para usuario {user_id}...")
            response = requests.get(
                "http://localhost:5000/recommend",
                params={'user_id': user_id},
                timeout=10
            )
            
            if response.status_code == 200:
                data = response.json()
                item_ids = data.get('item_ids', [])
                if len(item_ids) > 0:
                    print_success(f"Usuario {user_id}: {len(item_ids)} recomendaciones")
                    print_info(f"Items recomendados: {item_ids[:5]}")
                else:
                    print_warning(f"Usuario {user_id}: No hay recomendaciones disponibles")
            elif response.status_code == 404:
                error_data = response.json()
                if 'no entrenado' in error_data.get('error', '').lower():
                    print_warning(f"Usuario {user_id}: Modelo no entrenado aún")
                else:
                    print_warning(f"Usuario {user_id}: {error_data.get('error', 'No encontrado')}")
            else:
                print_error(f"Usuario {user_id}: Error {response.status_code}")
                
        except Exception as e:
            print_error(f"Usuario {user_id}: {str(e)}")

def test_laravel_routes():
    """Prueba las rutas principales de Laravel"""
    print("\n" + "="*60)
    print("PRUEBA 5: Rutas de Laravel")
    print("="*60)
    
    routes = [
        ("/", "Página principal"),
        ("/api/interactions/export-json", "API Exportación JSON"),
    ]
    
    for route, description in routes:
        try:
            response = requests.get(f"http://localhost:8000{route}", timeout=5, allow_redirects=False)
            if response.status_code in [200, 302, 301]:
                print_success(f"{description}: OK ({response.status_code})")
            else:
                print_warning(f"{description}: {response.status_code}")
        except Exception as e:
            print_error(f"{description}: {str(e)}")

def main():
    print("\n" + "="*60)
    print("SISTEMA DE PRUEBAS - Sistema de Recomendación")
    print("="*60)
    print(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    results = {
        'laravel_api': False,
        'python_service': False,
        'retrain': False,
    }
    
    # Prueba 1: Laravel API
    laravel_ok, interactions = test_laravel_api()
    results['laravel_api'] = laravel_ok
    
    # Prueba 2: Servicio Python
    python_ok = test_python_service()
    results['python_service'] = python_ok
    
    # Prueba 3: Reentrenamiento (solo si Python está corriendo)
    if python_ok and laravel_ok:
        results['retrain'] = test_retrain()
    
    # Prueba 4: Recomendaciones (solo si Python está corriendo)
    if python_ok:
        test_recommendations()
    
    # Prueba 5: Rutas de Laravel
    test_laravel_routes()
    
    # Resumen
    print("\n" + "="*60)
    print("RESUMEN DE PRUEBAS")
    print("="*60)
    
    for test, result in results.items():
        if result:
            print_success(f"{test}: OK")
        else:
            print_error(f"{test}: FALLÓ")
    
    print("\n" + "="*60)
    if all(results.values()):
        print_success("¡TODAS LAS PRUEBAS PASARON!")
    else:
        print_warning("Algunas pruebas fallaron. Revisa los mensajes arriba.")
    print("="*60 + "\n")

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nPruebas interrumpidas por el usuario")
        sys.exit(1)

