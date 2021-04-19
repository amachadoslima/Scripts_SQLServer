select 
		s.session_id, 
		r.[status], 
		r.blocking_session_id as blkby, 
		r.wait_type, 
		wait_resource, 
		r.wait_time / (1000 * 60) as waitm, 
		r.cpu_time, 
		r.logical_reads, 
		r.reads, 
		r.writes, 
		r.total_elapsed_time / (1000 * 60) as [elapsm], 
		substring(st.[text], (r.statement_start_offset / 2) + 1, ((case r.statement_end_offset when -1 then datalength(st.[text]) 
				else r.statement_end_offset end - r.statement_start_offset ) / 2 ) + 1) as statementtext, 
		coalesce(quotename(db_name(st.[dbid])) + N'.' + quotename(object_schema_name(st.objectid, st.dbid)) + N'.' 
				+ quotename(object_name(st.objectid, st.[dbid])), '') as commandtext, 
		r.command, 
		s.login_name, 
		s.[host_name], 
		s.[program_name], 
		s.last_request_end_time, 
		s.login_time, 
		r.open_transaction_count 
	from sys.dm_exec_sessions s 
       join sys.dm_exec_requests r on r.session_id = s.session_id 
       cross apply sys.dm_exec_sql_text(r.[sql_handle]) as st
	where r.session_id <> @@spid 
	order by r.cpu_time desc 