select 
		spid = s.session_id,
		s.[host_name],
		s.[program_name],
		s.[status],
		s.memory_usage,
		granted_memory = convert(int, r.granted_query_memory * 8.00), 
		t.[text],
		sourcedb = db_name(r.database_id), 
		workdb = db_name(dt.database_id),
		mg.*,
		su.*
	from sys.dm_exec_sessions s
		join sys.dm_db_session_space_usage su on s.session_id = su.session_id and su.database_id = db_id('tempdb') 
		join sys.dm_exec_connections c on s.session_id = c.most_recent_session_id 
		left outer join sys.dm_exec_requests r on r.session_id = s.session_id 
		left outer join (
			select session_id, database_id
				from sys.dm_tran_session_transactions t
					join sys.dm_tran_database_transactions dt on t.transaction_id = dt.transaction_id
				where dt.database_id = db_id('tempdb') 
			group by session_id, database_id
		) dt on s.session_id = dt.session_id
		cross apply sys.dm_exec_sql_text(coalesce(r.[sql_handle], c.most_recent_sql_handle)) t
		left outer join sys.dm_exec_query_memory_grants mg on s.session_id = mg.session_id 
	where (r.database_id = db_id('tempdb') 
		or dt.database_id = db_id('tempdb')) 
		--and s.[status] = 'running'
	order by spid;