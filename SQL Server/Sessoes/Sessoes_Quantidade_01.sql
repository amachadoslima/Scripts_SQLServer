select
		c.client_net_address, 
		isnull(rtrim(ltrim(s.[program_name])), 'n/a') as [program_name], 
		s.[host_name], 
		s.login_name, 
		count(c.session_id) as [connection_count]
	from sys.dm_exec_sessions s 
		join sys.dm_exec_connections c on s.session_id = c.session_id
	group by c.client_net_address, s.[program_name], s.[host_name], s.login_name
	order by [connection_count] desc