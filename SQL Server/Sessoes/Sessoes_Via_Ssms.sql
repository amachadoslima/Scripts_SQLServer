select 
		s.session_id 
		,s.login_time
		,s.original_login_name
		,s.login_name
		,s.[host_name]
		,s.[program_name]
	from sys.dm_exec_sessions s 
		join  sys.dm_exec_connections c on s.session_id = c.session_id
	where lower(s.[program_name]) = 'microsoft sql server management studio'