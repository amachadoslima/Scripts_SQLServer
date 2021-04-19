select 
		a.session_id,
		a.login_time,
		a.[host_name],
		a.[program_name],
		a.login_name,
		a.[status],
		a.cpu_time,
		a.memory_usage,
		a.last_request_start_time,
		a.last_request_end_time,
		a.transaction_isolation_level,
		a.[lock_timeout],
		a.[deadlock_priority],
		a.row_count,
		c.[text]
	from sys.dm_exec_sessions a with(nolock)
		join sys.dm_exec_connections b with(nolock)	on	a.session_id = b.session_id
		cross apply sys.dm_exec_sql_text(most_recent_sql_handle) c
	where exists (select * from sys.dm_tran_session_transactions as t with(nolock) where t.session_id = a.session_id)
		and not exists (select * from sys.dm_exec_requests as r with(nolock) where r.session_id = a.session_id)