select max(session_id) as max_id 
	from sys.dm_exec_connections
go
select   
		c.session_id,
		c.net_transport,
		c.encrypt_option,
		c.auth_scheme,
		s.[host_name], 
		s.[program_name],
		s.client_interface_name,
		s.login_name,
		s.nt_domain,
		s.nt_user_name,
		s.original_login_name, 
		c.connect_time, 
		s.login_time, 
		st.*
	from sys.dm_exec_connections c
		left join sys.dm_exec_sessions s on c.session_id = s.session_id  
		left join sys.dm_exec_requests r on c.session_id = r.session_id
		outer apply sys.dm_exec_sql_text(r.[sql_handle]) st
	where c.session_id <> @@spid