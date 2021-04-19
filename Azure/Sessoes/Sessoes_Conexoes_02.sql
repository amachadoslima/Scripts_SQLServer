select
		c.session_id, 
		c.net_transport, 
		c.encrypt_option,
		s.status,
		c.auth_scheme, 
		s.[host_name], 
		s.[program_name],
		s.client_interface_name, 
		s.login_name, 
		s.nt_domain,
		s.nt_user_name, 
		s.original_login_name, 
		c.connect_time,
		s.login_time
	from sys.dm_exec_connections as c
		join sys.dm_exec_sessions as s on c.session_id = s.session_id
	order by c.connect_time asc