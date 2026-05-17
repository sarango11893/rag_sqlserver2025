#!/bin/bash

# ==============================================================================
# PROYECTO: RAG Nativo en SQL Server 2025 (Ecosistema Local)
# DESCRIPCIÓN: Comandos para inicializar los modelos de IA y el túnel de red.
# ==============================================================================

echo "=== [PASO 1] Inicializando Modelos en Ollama ==="

# 1. Descargar y ejecutar Llama 3 para el razonamiento y generación de respuestas
# Nota: Este comando dejará la terminal en modo interactivo con el modelo.
# Si solo quieres descargarlo sin ejecutar la consola de chat, usa: ollama pull llama3
ollama run llama3

# 2. En una NUEVA terminal, descargar el modelo optimizado para embeddings
# Este modelo transformará los textos del manual y las preguntas en vectores de 768 dimensiones.
ollama pull nomic-embed-text

echo "=== [PASO 2] Verificación de Modelos Locales ==="
# Listar los modelos instalados para asegurar que ambos están listos
ollama list


echo "=== [PASO 3] Crear Túnel Seguro con Ngrok ==="
# SQL Server 2025 exige endpoints HTTPS por seguridad.
# Ejecuta este comando en una terminal separada para mapear el puerto HTTP local
# de Ollama (11434) a una URL pública cifrada (HTTPS).
ngrok http 11434

# ==============================================================================
# INSTRUCCIONES POST-EJECUCIÓN:
# 1. Copia la URL generada por Ngrok (ej. https://abcdef123.ngrok-free.app).
# 2. Abre el script 'scripts/03_rag_pipeline.sql'.
# 3. Reemplaza la variable @NgrokURL con tu URL activa de Ngrok.
# ==============================================================================