USE MeuBanco
GO
BEGIN

	SET NOCOUNT ON

	DECLARE @LimitRows VARCHAR(50) = 1000
	DECLARE @TableName VARCHAR(100) = 'minha_tabela'
	DECLARE @FilterWhere VARCHAR(MAX)
	DECLARE @OrderBy VARCHAR(MAX) 

	DECLARE @Columns VARCHAR(MAX)
	DECLARE @QuotedData VARCHAR(MAX)
	DECLARE @SqlCommand VARCHAR(MAX)

	SELECT @Columns = STUFF((
		SELECT ',' + QUOTENAME([name])
		FROM sys.columns (NOLOCK)
		WHERE OBJECT_ID = OBJECT_ID(@TableName)
			AND is_identity <> 1
		ORDER BY column_id ASC
		FOR XML PATH('')), 1, 1, '')

	SELECT @QuotedData = STUFF((
		SELECT
			-- Trata campos do tipo datetime
			CASE system_type_id
				WHEN 61 THEN ' ISNULL(QUOTENAME(CONVERT(VARCHAR(23),' + [name]+',121),' + QUOTENAME('''','''''') + '),' + '''NULL''' + ')+'',''' + '+' 
				ELSE ' ISNULL(QUOTENAME(' + [name] + ',' + QUOTENAME('''','''''') + '),' + '''NULL''' + ')+'',''' + '+' 
			END
		FROM sys.columns (NOLOCK)
		WHERE OBJECT_ID = OBJECT_ID(@TableName)
			AND is_identity <> 1
		ORDER BY column_id ASC
		FOR XML PATH('')), 1, 1, '')

	SET @SqlCommand = 'SELECT TOP (' + @LimitRows + ') ''INSERT INTO ' +
					 @TableName + '(' + @Columns + 
					 ')VALUES(''' + '+' + SubString(@QuotedData, 1, Len(@QuotedData) - 5) + '+' + ''')''' + 
					 ' SQLCmd FROM ' + @TableName + ' ' + ISNULL(@FilterWhere, '') + ' ' + ISNULL(@OrderBy, '')

	PRINT @SqlCommand
	EXEC (@sqlCommand)

END
