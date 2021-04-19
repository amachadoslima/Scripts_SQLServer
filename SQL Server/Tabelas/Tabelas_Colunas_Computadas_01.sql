USE SIGERO_ADMIN 
GO
BEGIN
	
	SELECT O.[name] AS TBLNAME, C.[name] AS CLNAME, C.[definition] AS CLMNS
		FROM sys.computed_columns C
			JOIN sys.objects O ON O.[object_id] = C.[object_id]
		--WHERE O.[name] = 'teste'
		ORDER BY O.[name]

END