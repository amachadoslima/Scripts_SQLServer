select 
		mg.session_id as [spid],
		s.login_name as [login_name],
		s.[status],
		mg.dop as [grau_paralelismo],
		mg.request_time as [req_inicio], 
		cast(mg.requested_memory_kb / 1024 as decimal(10,2)) as [reqmemoriamb],
		cast(mg.required_memory_kb / 1024 as decimal(10,2)) as [reqminmemoriamb],
		mg.wait_time_ms as [tempoespera], 
		st.[text]
	from sys.dm_exec_query_memory_grants mg
		join sys.dm_exec_requests r on mg.session_id = r.session_id
		outer apply sys.dm_exec_sql_text(r.[sql_handle]) st
		join sys.dm_exec_sessions s on s.session_id = mg.session_id
	where mg.grant_time is null