select distinct	
		schema_name([schema_id]) + '.' + t.[name] as [name],
		ix.[name] as ixname, 
		user_seeks, 
		user_scans, 
		user_lookups, 
		user_updates, 
		last_user_seek, 
		last_user_scan, 
		last_user_lookup, 
		last_user_update   
	from sys.dm_db_index_usage_stats i 
		join sys.tables t on t.[object_id] = i.[object_id]
		join sys.indexes ix on i.index_id = ix.index_id and ix.[object_id] = i.[object_id]
	where database_id = db_id()
	order by last_user_scan desc