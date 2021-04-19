select 
		ws.wait_duration_ms,
		ws.wait_type,
		es.[status],
		t.[text],
		qp.query_plan,
		ws.session_id,
		es.cpu_time,
		es.memory_usage,
		es.logical_reads,
		es.total_elapsed_time,
		es.[program_name],
		db_name(r.database_id) as dbname,
		ws.blocking_session_id,
		r.wait_resource,	
		es.login_name,
		r.command,
		r.last_wait_type
	from sys.dm_os_waiting_tasks ws
		join sys.dm_exec_requests r on ws.session_id = r.session_id
		join sys.dm_exec_sessions es on es.session_id = r.session_id
		cross apply sys.dm_exec_sql_text (r.[sql_handle]) t
		cross apply sys.dm_exec_query_plan (r.plan_handle) qp
	where es.is_user_process = 1