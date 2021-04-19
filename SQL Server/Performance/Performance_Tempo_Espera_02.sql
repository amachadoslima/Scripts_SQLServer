begin

	select 
			wt.session_id,
			wt.wait_duration_ms,
			wt.wait_type,
			wt.exec_context_id,
			db_name(r.database_id) as databasename,
			r.command,
			st.[text]
		from sys.dm_os_waiting_tasks wt
			join sys.dm_exec_sessions s on wt.session_id = s.session_id
			join sys.dm_exec_requests r on r.session_id = wt.session_id
			outer apply sys.dm_exec_sql_text(r.[sql_handle]) st
		where wt.session_id > 50
		order by wt.session_id, wt.exec_context_id
		option(recompile);

end