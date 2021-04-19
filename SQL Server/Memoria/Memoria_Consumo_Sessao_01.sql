SELECT 
		session_id, 
		(requested_memory_kb / 1024.) as requested_mem_mb, 
		(granted_memory_kb / 1024.) as granted_mem_mb, 
		[text]
	FROM sys.dm_exec_query_memory_grants
		CROSS APPLY sys.dm_exec_sql_text(sql_handle)