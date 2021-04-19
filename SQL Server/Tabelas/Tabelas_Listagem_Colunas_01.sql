SELECT distinct
		schema_name(o.schema_id)+'.'+o.name as 'Table Name',
		c.name 'Column Name',
		t.Name 'Data Type',
		c.max_length 'Max Length',
		c.precision  as 'Precision',
		c.scale as 'Scale' ,
		c.is_nullable as 'Is Nullable',
		ISNULL(i.is_primary_key, 0) 'Primary Key'
	FROM sys.columns c
		JOIN sys.types t ON c.user_type_id = t.user_type_id
		LEFT OUTER JOIN sys.index_columns ic ON ic.object_id = c.object_id AND ic.column_id = c.column_id
		LEFT OUTER JOIN sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
		JOIN sys.objects o ON c.object_id = o.object_id
	WHERE o.type = 'U'