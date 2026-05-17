# 🧠 Private & Local RAG Architecture inside SQL Server 2025

[![SQL Server](https://img.shields.io/badge/SQL_Server-2025-red?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)](https://www.microsoft.com/en-us/sql-server/sql-server-2025)
[![Ollama](https://img.shields.io/badge/Ollama-Local_LLM-orange?style=for-the-badge&logo=ollama&logoColor=white)](https://ollama.com/)
[![Ngrok](https://img.shields.io/badge/Ngrok-Secure_Tunnel-blue?style=for-the-badge&logo=ngrok&logoColor=white)](https://ngrok.com)

> Sistema **RAG (Retrieval-Augmented Generation)** ejecutado 100% de forma nativa y local en la capa de datos. Aprovecha el soporte de almacenamiento vectorial de **SQL Server 2025** y se comunica con un ecosistema de IA local sin exponer información confidencial a la nube.

---

## 🚀 Arquitectura del Sistema & Flujo de Datos

El pipeline se divide en dos flujos principales controlados directamente por la base de datos:

### Flujo 1 — Ingestión y Embedding

\```
Manual Técnico (Texto Plano)
  └─► sp_invoke_external_rest_endpoint
        └─► Ngrok (HTTPS)
              └─► Ollama (nomic-embed-text)
                    └─► Vector (768d)
                          └─► VECTOR(768) en tabla SQL
\```

### Flujo 2 — Pipeline de Consulta

\```
Pregunta del Usuario
  └─► Inferencia Vectorial
        └─► VECTOR_DISTANCE (similitud coseno)
              └─► Prompt Enriquecido con contexto
                    └─► Ollama (Llama 3)
                          └─► Respuesta final en consola SQL
\```

### Descripción del Pipeline

| Paso | Componente | Descripción |
|------|-----------|-------------|
| 1 | **T-SQL Input** | El usuario ejecuta un stored procedure consultando el manual indexado |
| 2 | **Embeddings** | SQL Server consume via HTTP el modelo `nomic-embed-text` en Ollama a través de Ngrok |
| 3 | **Búsqueda Vectorial** | Similitud coseno con `VECTOR_DISTANCE` contra la base de conocimiento |
| 4 | **Inferencia Local** | El fragmento relevante se añade al prompt y se envía a `Llama 3` |

---

## 🛠️ Requisitos e Infraestructura Local

### 1. Modelos en Ollama

Instala [Ollama](https://ollama.com/) y descarga los modelos necesarios:

\```bash
# Modelo de lenguaje para generación de respuestas
ollama run llama3

# Modelo especializado en embeddings (vectores de 768 dimensiones)
ollama pull nomic-embed-text
\```

### 2. Bypass de Red Cifrada con Ngrok

SQL Server 2025 exige endpoints **HTTPS** para sus funciones REST nativas. Dado que Ollama expone un puerto HTTP plano (`http://localhost:11434`), se usa Ngrok como proxy inverso:

\```bash
ngrok http 11434
\```

> ⚠️ **Nota crítica:** Copia la URL pública generada (ej. `https://abcdef123.ngrok-free.app`). Deberás configurarla en tus scripts SQL.

---

## 💾 Despliegue de los Scripts de Base de Datos

Ejecuta los scripts de la carpeta `/scripts` en el siguiente orden estricto:

### 📑 Paso 1 — Inicializar la Tabla Vectorial (`01_init_dataset.sql`)

Crea la base de datos y la tabla de destino con el nuevo tipo de dato `VECTOR`, e inserta los manuales del CRM en texto plano.

\```sql
CREATE TABLE BaseConocimientoCRM (
    ID                 INT IDENTITY(1,1) PRIMARY KEY,
    ManualDeReferencia VARCHAR(150)    NOT NULL,
    ParrafoExtraido    NVARCHAR(MAX)   NOT NULL,
    VectorEmbeddings   VECTOR(768)     NULL
);
\```

### 📑 Paso 2 — Habilitar Endpoints Externos (`02_api_config.sql`)

Ejecuta con permisos de `sysadmin` para permitir peticiones HTTP salientes desde el motor de SQL Server:

\```sql
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;

EXEC sp_configure 'external rest endpoints status', 1;
RECONFIGURE;
\```

### 📑 Paso 3 — Orquestar el Pipeline RAG (`03_rag_pipeline.sql`)

1. Abre el archivo y localiza la variable `@NgrokURL`
2. Reemplaza su valor por tu URL activa de Ngrok
3. Ejecuta el script:
   - **Primera parte:** cursor que llama a Ollama en batch para poblar `VectorEmbeddings`
   - **Segunda parte:** compila el stored procedure de consulta

---

## ⚡ Pruebas de Inferencia

Una vez completado el despliegue, consulta tu base de datos en lenguaje natural desde SSMS o VS Code:

\```sql
EXEC SP_PreguntarCRM '¿Es obligatorio ingresar el email al añadir un prospecto en el menú izquierdo?';
\```

**Respuesta generada en consola:**

\```json
[
  {
    "RespuestaAsistenteIA": "Sí. De acuerdo con la Guía de Usuario del Sistema CRM Interno, al navegar al menú izquierdo, entrar a 'Prospectos' y presionar el botón azul 'Añadir Nuevo', es estrictamente obligatorio rellenar el campo de Correo Electrónico para registrar exitosamente al cliente potencial."
  }
]
\```

---

## 📂 Estructura del Repositorio

\```
rag-sqlserver2025-local/
│
├── README.md                  ← Documentación principal del proyecto
├── architecture-flow.png      ← Diagrama visual de la arquitectura técnica
│
├── scripts/
│   ├── 01_init_dataset.sql    ← DDL de tablas vectoriales y datos semilla
│   ├── 02_api_config.sql      ← Configuración de red Outbound (REST)
│   └── 03_rag_pipeline.sql    ← Cursor de embedding batch + procedimiento RAG
│
└── config/
    └── ollama-commands.sh     ← Script Bash de orquestación de servicios
\```

---

## 🔒 Ventajas de esta Arquitectura

| Ventaja | Detalle |
|---------|---------|
| 💰 **Costo cero por token** | Llama 3 y Nomic-Embed corren localmente; sin facturas de APIs comerciales |
| 🔐 **Gobierno de datos** | La información confidencial jamás sale de la infraestructura de la empresa |
| 🧩 **Sin frameworks intermedios** | No requiere LangChain ni LlamaIndex; toda la lógica vive en T-SQL avanzado |

---

*Desarrollado con fines de portafolio técnico para la integración de **Inteligencia Artificial Generativa aplicada a Bases de Datos Relacionales** (Generative AI & Data Engineering).*
