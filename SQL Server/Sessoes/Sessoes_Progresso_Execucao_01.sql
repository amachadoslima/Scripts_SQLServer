select 
		a.session_id, 
		a.row_count, 
		a.estimate_row_count, 
		(b.[name] + '..' + object_name(a.[object_id], b.database_id)) as obj, 
		convert(char(19), dateadd(millisecond, -a.first_active_time, sysdatetime()), 121) as first_active_time, 
		convert(char(19), dateadd(millisecond, -a.last_active_time, sysdatetime()), 121) as last_active_time, 
		a.open_time, 
		a.scan_count, 
		a.logical_read_count,
		a.physical_read_count,
		a.write_page_count,
		a.thread_id,
		c.[text]
	from sys.dm_exec_query_profiles a
		join sys.databases b on a.database_id = b.database_id
		cross apply sys.dm_exec_sql_text(a.[sql_handle]) as c
	order by a.session_id asc, a.row_count desc;