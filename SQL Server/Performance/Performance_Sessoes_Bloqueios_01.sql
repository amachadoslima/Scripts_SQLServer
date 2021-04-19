select
		r.session_id,
		r.blocking_session_id,
		r.database_id,
		r.command,
		s.last_request_start_time,
		s.login_name,
		r.last_wait_type,
		r.[status]
	from sys.dm_exec_requests r
		join sys.dm_exec_sessions s on r.session_id = s.session_id
	where (r.blocking_session_id > 0 and r.blocking_session_id <> r.session_id)
		or	r.session_id in(
			select blocking_session_id 
				from sys.dm_exec_requests 
				where blocking_session_id > 0 and blocking_session_id <> session_id
		)