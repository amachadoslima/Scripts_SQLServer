select	
		r.session_id,
		blocking_session_id,
		s.[host_name],
		c.client_net_address,
		c.client_tcp_port,
		db_name(r.database_id) as [db_name],
		s.login_name, 
		r.status,
		r.command,
		r.start_time,
		r.percent_complete,
		r.reads,
		r.writes,
		r.cpu_time, 
		(r.total_elapsed_time / 1000.0) as total_elapsed_time,
		--,dateadd(microsecond, r.total_elapsed_time, '1900-01-01 00:00:00')
		r.command,
		r.wait_type,
		r.percent_complete, 
		r.wait_time, 
		r.[ansi_warnings],
		case s.transaction_isolation_level
			when '0' then 'unspecified' when '1' then 'readuncomitted' when '2' then 'readcommitted'
			when '3' then 'repeatable' when '4' then 'serializable' when '5' then 'snapshot' else '' end as 'session',
		case r.transaction_isolation_level 
			when '0' then 'unspecified' when '1' then 'readuncomitted' when '2' then 'readcommitted'
			when '3' then 'repeatable' when '4' then 'serializable' when '5' then 'snapshot' else '' end as request, 
		r.percent_complete, 
		substring(isnull(st.[text], ''), 0, 50) as sqltext,
		st.[text]
	from sys.dm_exec_requests r
		cross apply sys.dm_exec_sql_text(sql_handle) as st
		join sys.dm_exec_sessions s on s.session_id = r.session_id
		join sys.dm_exec_connections c on s.session_id = c.session_id
	where r.session_id <> @@spid
		--and r.wait_type is not null
		--and r.status <> 'running'
		--and (r.total_elapsed_time / 1000.0) > 60