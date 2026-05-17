-- ==============================================================================
-- FASE 1: CREACIÓN DEL DATASET Y ESTRUCTURA VECTORIAL
-- PROYECTO: RAG Nativo en SQL Server 2025
-- ==============================================================================

-- 1. Crear la base de datos de pruebas (si no existe)
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'DB_RAG_Local')
BEGIN
    CREATE DATABASE DB_RAG_Local;
END
GO

USE DB_RAG_Local;
GO

-- 2. Crear la tabla con soporte nativo para vectores (SQL Server 2025)
-- Nota: Usamos 768 dimensiones porque es el estándar de nomic-embed-text
IF OBJECT_ID('BaseConocimientoCRM', 'U') IS NOT NULL
    DROP TABLE BaseConocimientoCRM;
GO

CREATE TABLE BaseConocimientoCRM (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    ManualDeReferencia VARCHAR(150) NOT NULL,
    ParrafoExtraido NVARCHAR(MAX) NOT NULL,
    VectorEmbeddings VECTOR(768) NULL -- Aquí se almacena la semántica del texto
);
GO

-- 3. Insertar los datos crudos del manual (Materia prima para el RAG)
INSERT INTO BaseConocimientoCRM (ManualDeReferencia, ParrafoExtraido)
VALUES (
    'Guía de Usuario - Sistema CRM Interno', 
    'Para registrar un nuevo cliente potencial en el CRM, navegue al menú izquierdo, haga clic en ''Prospectos'' y luego presione el botón azul ''Añadir Nuevo''. Es obligatorio rellenar el campo de Correo Electrónico.'
);
GO

-- Verificación inicial
SELECT ID, ManualDeReferencia, LEFT(ParrafoExtraido, 50) + '...' AS fragmento, VectorEmbeddings 
FROM BaseConocimientoCRM;
GO