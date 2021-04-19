select 
		s.session_id as 'session_id',
		coalesce(s.original_login_name, '') as 'login_name',
		coalesce(s.host_name, '') as 'hostname',
		coalesce(s.last_request_end_time, s.last_request_start_time) as 'last_batch',
		s.[status],
		coalesce(r.blocking_session_id, 0) as 'blocked_by',
		coalesce(r.wait_type, 'miscellaneous') as 'waittype',
		coalesce(r.wait_time, 0) as 'waittime',
		coalesce(r.last_wait_type, 'miscellaneous') as 'lastwaittype',
		coalesce(r.wait_resource, '') as 'waitresource',
		coalesce(db_name(r.database_id), 'no info') as 'dbid',
		coalesce(r.command, 'awaiting command') as 'cmd',
		sql_text = st.[text],
		transaction_isolation =
			case s.transaction_isolation_level
			when 0 then 'unspecified'
			when 1 then 'read uncommitted'
			when 2 then 'read committed'
			when 3 then 'repeatable'
			when 4 then 'serializable'
			when 5 then 'snapshot'
		end,
		coalesce(s.cpu_time, 0) + coalesce(r.cpu_time, 0) as 'cpu',
		coalesce(s.reads,0) + coalesce(s.writes ,0) + coalesce(r.reads, 0) + coalesce(r.writes, 0) as 'physical_io',
		coalesce(r.open_transaction_count, -1) as 'open_tran',
		coalesce(s.program_name, '') as 'program_name',
		s.login_time,
		qp.query_plan
	from sys.dm_exec_sessions s
			left outer join sys.dm_exec_connections c on s.session_id = c.session_id
			left outer join sys.dm_exec_requests r on s.session_id = r.session_id
			left outer join sys.server_principals p on s.security_id = p.[sid]
			left outer join sys.dm_os_tasks t on s.session_id = t.session_id
			left outer join sys.dm_os_threads th on t.worker_address = th.worker_address
			outer apply sys.dm_exec_sql_text(r.[sql_handle]) as st
			cross apply sys.dm_exec_query_plan (r.plan_handle) qp
	where s.is_user_process = 1
		and s.session_id <> @@spid
	order by s.session_id
	
----6:1:46921644
--select db_name(6)
--dbcc traceon (3604)
--go
--dbcc page (6, 1, 46921644) 
--dbcc traceoff (3604)