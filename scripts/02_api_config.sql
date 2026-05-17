-- ==============================================================================
-- FASE 2: CONFIGURACIÓN DE SEGURIDAD Y ACCESO DE RED (OUTBOUND)
-- ==============================================================================

USE DB_RAG_Local;
GO

-- 1. Habilitar la configuración avanzada para ejecutar endpoints externos
-- (Este paso suele requerir privilegios de Administrador de Sysadmin)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'external rest endpoints status', 1;
RECONFIGURE;
GO

-- 2. Crear una clave maestra de la base de datos para cifrar credenciales si fuera necesario
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'TuPasswordSeguro123!';
END
GO

PRINT 'Configuración de red y endpoints externos completada en SQL Server.';
GO