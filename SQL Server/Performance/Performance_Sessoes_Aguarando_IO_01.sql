select	
		i.io_type, 
		db_name(t.[dbid]) as dbname, '['+object_schema_name(t.objectid, t.[dbid]) +'.'+object_name(t.objectid, t.[dbid])+']' as [object_name],
		i.io_pending,
		i.scheduler_address,
		i.io_handle,
		s.scheduler_id,
		s.cpu_id,
		s.pending_disk_io_count,
		r.session_id,
		r.command,
		r.cpu_time,
		t.[text]
	from sys.dm_io_pending_io_requests i
		join sys.dm_os_schedulers s on i.scheduler_address = s.scheduler_address
		join sys.dm_exec_requests as r on s.scheduler_id = r.scheduler_id
		cross apply sys.dm_exec_sql_text(r.[sql_handle]) as t