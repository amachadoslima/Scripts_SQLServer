select 
		db_name(database_id) as [dbname], 
		(count(*) * 8 / 1024.0) as [cached_size_mb]
	from sys.dm_os_buffer_descriptors
	where db_name(database_id) is not null
		and database_id > 4
	group by db_name(database_id)
	order by [cached_size_mb] desc
	option(recompile)