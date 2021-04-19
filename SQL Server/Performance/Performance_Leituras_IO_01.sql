select 
		cast(db_name(a.database_id) as varchar) as [database_name],
		b.physical_name, * 
	from sys.dm_io_virtual_file_stats(null, null) a
		join sys.master_files b on a.database_id = b.database_id and a.[file_id] = b.[file_id]
	order by a.num_of_reads desc