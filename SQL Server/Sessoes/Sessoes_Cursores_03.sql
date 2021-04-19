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
			c.is_open, 
			con.[text],
			l.resource_type,
			d.[name],
			l.request_type,
			l.request_Status,
			l.request_reference_count,
			l.request_lifetime,
			l.request_owner_type
		FROM sys.dm_exec_cursors(0) c
			LEFT OUTER JOIN (
				SELECT * 
					FROM sys.dm_exec_connections c 
						CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) mr
			) con on c.session_id = con.session_id
			LEFT OUTER JOIN sys.dm_exec_sessions s on s.session_id = c.session_id
			LEFT OUTER JOIN sys.dm_tran_locks l on l.request_session_id = c.session_id
			LEFT OUTER JOIN sys.databases d on d.database_id = l.resource_database_id
END