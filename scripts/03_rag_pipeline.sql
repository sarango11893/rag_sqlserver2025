-- ==============================================================================
-- FASE 3: PIPELINE RAG (EMBEDDINGS, BÚSQUEDA SEMÁNTICA E INFERENCIA)
-- ==============================================================================

USE DB_RAG_Local;
GO

/* ==============================================================================
PASO A: SCRIPT DE AUTOMATIZACIÓN PARA VECTORIZAR LA TABLA (BATCH EMBEDDING)
==============================================================================
*/
DECLARE @NgrokURL VARCHAR(250) = 'https://TU_URL_DE_NGROK.ngrok-free.app'; -- CAMBIAR POR TU URL DE NGROK
DECLARE @ID_Actual INT;
DECLARE @TextoActual NVARCHAR(MAX);
DECLARE @PayloadEmbedding NVARCHAR(MAX);
DECLARE @ResponseEmbedding NVARCHAR(MAX);

-- Cursor simple para recorrer los registros que aún no tienen vector
DECLARE cursor_manuales CURSOR FOR 
SELECT ID, ParrafoExtraido FROM BaseConocimientoCRM WHERE VectorEmbeddings IS NULL;

OPEN cursor_manuales;
FETCH NEXT FROM cursor_manuales INTO @ID_Actual, @TextoActual;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Construir el formato JSON que Ollama espera para /api/embeddings
    SET @PayloadEmbedding = JSON_OBJECT('model': 'nomic-embed-text', 'prompt': @TextoActual);

    -- Llamar de forma nativa a la API local a través del túnel HTTPS de Ngrok
    EXEC sys.sp_invoke_external_rest_endpoint
        @url = @NgrokURL + '/api/embeddings',
        @method = 'POST',
        @payload = @PayloadEmbedding,
        @response = @ResponseEmbedding OUTPUT;

    -- Extraer el array numérico del JSON y guardarlo usando CAST al tipo VECTOR
    UPDATE BaseConocimientoCRM
    SET VectorEmbeddings = CAST(JSON_VALUE(@ResponseEmbedding, '$.embedding') AS VECTOR(768))
    WHERE ID = @ID_Actual;

    FETCH NEXT FROM cursor_manuales INTO @ID_Actual, @TextoActual;
END

CLOSE cursor_manuales;
DEALLOCATE cursor_manuales;
GO


/* ==============================================================================
PASO B: CREACIÓN DEL PROCEDIMIENTO ALMACENADO RAG (CONSULTAS INTELIGENTES)
==============================================================================
*/
CREATE OR ALTER PROCEDURE SP_PreguntarCRM
    @PreguntaUsuario NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    -- URL estática de tu túnel (En producción esto debería mapearse en una tabla de configuración)
    DECLARE @NgrokURL VARCHAR(250) = 'https://TU_URL_DE_NGROK.ngrok-free.app'; -- CAMBIAR POR TU URL DE NGROK
    
    DECLARE @PayloadEmbedding NVARCHAR(MAX);
    DECLARE @ResponseEmbedding NVARCHAR(MAX);
    DECLARE @VectorConsulta VECTOR(768);
    DECLARE @ContextoRecuperado NVARCHAR(MAX);
    DECLARE @PromptFinal NVARCHAR(MAX);
    DECLARE @PayloadGeneracion NVARCHAR(MAX);
    DECLARE @ResponseFinal NVARCHAR(MAX);

    -- 1. Vectorizar la pregunta del usuario en tiempo real
    SET @PayloadEmbedding = JSON_OBJECT('model': 'nomic-embed-text', 'prompt': @PreguntaUsuario);
    
    EXEC sys.sp_invoke_external_rest_endpoint
        @url = @NgrokURL + '/api/embeddings',
        @method = 'POST',
        @payload = @PayloadEmbedding,
        @response = @ResponseEmbedding OUTPUT;

    SET @VectorConsulta = CAST(JSON_VALUE(@ResponseEmbedding, '$.embedding') AS VECTOR(768));

    -- 2. Búsqueda Semántica: Extraer el fragmento del manual más cercano (Similitud de Cosenos)
    SELECT TOP 1 @ContextoRecuperado = ParrafoExtraido
    FROM BaseConocimientoCRM
    ORDER BY VECTOR_DISTANCE('cosine', VectorEmbeddings, @VectorConsulta);

    -- 3. Inferencia con Llama 3: Enviar la pregunta enriquecida con el contexto técnico hallado
    SET @PromptFinal = 'Eres un asistente técnico del CRM de la empresa. Responde de forma concisa y basándote ESTRICTAMENTE en el siguiente contexto. ' + 
                       'Contexto: ' + @ContextoRecuperado + ' ' +
                       'Pregunta del usuario: ' + @PreguntaUsuario;

    SET @PayloadGeneracion = JSON_OBJECT('model': 'llama3', 'prompt': @PromptFinal, 'stream': false);

    EXEC sys.sp_invoke_external_rest_endpoint
        @url = @NgrokURL + '/api/generate',
        @method = 'POST',
        @payload = @PayloadGeneracion,
        @response = @ResponseFinal OUTPUT;

    -- 4. Retornar el texto plano generado por el LLM en local
    SELECT JSON_VALUE(@ResponseFinal, '$.response') AS RespuestaAsistenteIA;
END;
GO

/*
-- CÓMO PROBAR TU PIPELINE RAG:
EXEC SP_PreguntarCRM '¿Es obligatorio ingresar el email al añadir un prospecto en el menú izquierdo?';
*/