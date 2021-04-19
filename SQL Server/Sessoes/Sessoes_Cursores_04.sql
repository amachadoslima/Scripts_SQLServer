USE master 
GO
BEGIN
	
	SELECT 
			s.session_id,
			s.[host_name],
			s.[program_name],
			s.client_interface_name,
			s.login_name,
			c.cursor_id,
			c.properties,
			c.creation_time,
			c.worker_time as worker_time_ms,
			cast(dateadd(second, (c.worker_time / 1000000), cast('1900-01-01 00:00:00.000' as datetime2)) as time) as [worker_time],
			c.is_open, 
			c.is_async_population,
			c.is_close_on_commit,
			c.[fetch_status],
			con.[text] as [text_cursor],
			t.[text],
			l.resource_type,
			d.[name],
			l.request_type,
			l.request_status,
			l.request_reference_count,
			l.request_lifetime,
			l.request_owner_type
		FROM sys.dm_exec_cursors(0) c
			LEFT OUTER JOIN sys.dm_exec_sessions s on s.session_id = c.session_id
			LEFT OUTER JOIN sys.dm_tran_locks l on l.request_session_id = c.session_id
			LEFT OUTER JOIN sys.databases d on d.database_id = l.resource_database_id
			CROSS APPLY sys.dm_exec_sql_text(c.[sql_handle]) t
			LEFT OUTER JOIN (
				SELECT * 
					FROM sys.dm_exec_connections c 
						CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) mr
			) con on c.session_id = con.session_id

END