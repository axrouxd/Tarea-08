#!/usr/bin/env python3
"""
Script de prueba para verificar la obtención de datos desde Laravel
"""
import requests
import json
import os

LARAVEL_API_URL = os.getenv('LARAVEL_API_URL', 'http://localhost:8000')

def test_fetch_interactions():
    """Prueba la obtención de interacciones desde Laravel"""
    print("=" * 50)
    print("Probando obtención de datos desde Laravel")
    print("=" * 50)
    
    url = f"{LARAVEL_API_URL}/api/interactions/export-json"
    print(f"\nURL: {url}")
    
    try:
        response = requests.get(url, timeout=30)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"\n✓ Datos obtenidos exitosamente")
            print(f"Total de interacciones: {len(data)}")
            
            if len(data) > 0:
                print("\nPrimeras 3 interacciones:")
                for i, interaction in enumerate(data[:3], 1):
                    print(f"\n{i}. Usuario {interaction['user_id']} -> Item {interaction['item_id']}")
                print(f"   Rating: {interaction['rating']}/5")
                print(f"   Tipo: {interaction['interaction_type']}")
            
            # Estadísticas
            if len(data) > 0:
                df_data = pd.DataFrame(data)
                print("\n" + "=" * 50)
                print("ESTADÍSTICAS:")
                print("=" * 50)
                print(f"Usuarios únicos: {df_data['user_id'].nunique()}")
                print(f"Items únicos: {df_data['item_id'].nunique()}")
                print(f"Rating promedio: {df_data['rating'].mean():.2f}")
                print(f"Rating mínimo: {df_data['rating'].min()}")
                print(f"Rating máximo: {df_data['rating'].max()}")
            
            return data
        else:
            print(f"\n✗ Error: {response.status_code}")
            print(f"Respuesta: {response.text}")
            return []
            
    except requests.exceptions.ConnectionError:
        print("\n✗ Error: No se pudo conectar con Laravel")
        print(f"   Asegúrate de que Laravel esté corriendo en {LARAVEL_API_URL}")
        return []
    except Exception as e:
        print(f"\n✗ Error: {str(e)}")
        return []

if __name__ == '__main__':
    try:
        import pandas as pd
        data = test_fetch_interactions()
        
        if len(data) > 0:
            print("\n" + "=" * 50)
            print("✓ Los datos están listos para entrenar el modelo")
            print("=" * 50)
            print("\nPara entrenar el modelo, ejecuta:")
            print("  curl -X POST http://localhost:5000/retrain")
        else:
            print("\n" + "=" * 50)
            print("✗ No hay datos disponibles para entrenar")
            print("=" * 50)
            print("\nAsegúrate de:")
            print("  1. Que Laravel esté corriendo")
            print("  2. Que haya interacciones en la base de datos")
            print("  3. Que la ruta /api/interactions/export-json sea accesible")
    except ImportError:
        print("Error: pandas no está instalado")
        print("Ejecuta: pip install pandas")

