# Motor de Respuestas RAG Nativo en SQL Server 2025 (100% Local & Privado)

Este proyecto implementa una arquitectura de **Generación Aumentada por Recuperación (RAG)** de extremo a extremo sin salir de la base de datos, utilizando las capacidades nativas de **SQL Server 2025**, **Ollama** para la ejecución local de LLMs y **Ngrok** para resolver restricciones de seguridad de red cifrada.

## 🚀 Arquitectura del Flujo
El sistema procesa las consultas de los usuarios bajo el siguiente flujo de datos:
1. **T-SQL Input:** El usuario ejecuta un procedimiento almacenado enviando una duda sobre el manual del CRM.
2. **Generación de Embeddings:** SQL Server consume mediante HTTP nativo el modelo `nomic-embed-text` en Ollama a través del túnel seguro de Ngrok.
3. **Búsqueda Vectorial:** Se computa la similitud de cosenos utilizando el nuevo tipo de dato nativo `VECTOR` de SQL Server 2025 contra los fragmentos de manuales indexados.
4. **Inferencia Local:** El fragmento más relevante (contexto) se añade al prompt y se envía a `Llama 3` en Ollama, retornando la respuesta final redactada a la consola de SQL.

## 🛠️ Requisitos e Infraestructura Local

### 1. Preparación de Modelos (Ollama)
Ejecuta en tu terminal para descargar y levantar los modelos de lenguaje y embeddings:
```bash
# Servidor de inferencia y modelo de texto
ollama run llama3

# Modelo optimizado para generar vectores numéricos de 768 dimensiones
ollama pull nomic-embed-text