select
		schema_name(o.[schema_id])+'.'+o.[name] as tbl_name,
		i.[name] as index_name,
		u.user_seeks,
		u.user_scans,
		u.user_updates
	from sys.dm_db_index_usage_stats u
		join sys.objects o on u.[object_id] = o.[object_id]
		join sys.indexes i on i.index_id = u.index_id and u.[object_id] = i.[object_id]
	where i.is_primary_key = 0 --this line excludes primary key constarint
		and i. is_unique = 0 --this line excludes unique key constarint
		and u.user_updates <> 0 -- this line excludes indexes sql server hasn’t done any work with
		and u. user_lookups = 0
		and u.user_seeks = 0
		and u.user_scans = 0
	order by u.user_updates desc
