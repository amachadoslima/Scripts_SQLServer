USE DERSA_N3 
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF

DECLARE @TableName	SYSNAME
DECLARE @IndexName	SYSNAME
DECLARE @Sql		VARCHAR(MAX)
DECLARE @Key		BIGINT
DECLARE @Lockres	VARCHAR(50)

--KEY: 7:72057596299313152 (1c0097735df0)

SET @Key = 72057596299313152
SET @Lockres = '(1c0097735df0)'

SELECT 
		@TableName = o.[name], 
		@IndexName = i.[name]
	FROM sys.partitions p
		JOIN sys.objects o ON p.[object_id] = o.[object_id]
		JOIN sys.indexes i ON p.[object_id] = i.[object_id] AND p.index_id = i.index_id
	WHERE p.hobt_id = @Key

SELECT 
	@Key as [Key], 
	@Lockres as [LockRes], 
	@TableName as Table_Name, 
	@IndexName as Index_Name


SET @Sql = 'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT * FROM [' + @TableName + '] WHERE %%lockres%% = ''' + @Lockres + ''';'

PRINT (@Sql)
EXECUTE (@Sql)