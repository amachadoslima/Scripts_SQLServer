USE SIGERO_ADMIN
GO
BEGIN

	select 
			schema_name(o.[schema_id]) + '.' + object_name(c.[object_id]) as table_name,
			column_id,
			c.[name] as column_name,
			type_name(user_type_id) as data_type,
			[definition]
		from sys.computed_columns c
			join sys.objects o on o.[object_id] = c.[object_id]
		order by table_name, column_id

END