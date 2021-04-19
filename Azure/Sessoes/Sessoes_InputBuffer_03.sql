select 
		c.session_id, 
		s.[status], 
		s.[host_name],
		s.login_name, 
		dateadd(hour, -3, c.connect_time) as connect_time, 
		dateadd(hour, -3, s.last_request_start_time) as last_request_start_time, 
		i.event_info as [sqltext],
		i.parameters,
		i.event_type,
		s.reads, 
		s.writes, 
		s.logical_reads, 
		s.row_count
	from sys.dm_exec_connections as c with(nolock)
		join sys.dm_exec_sessions as s with(nolock) on c.session_id = s.session_id
		--join sys.dm_exec_requests as r with(nolock) on s.session_id = r.session_id
		outer apply sys.dm_exec_input_buffer(s.session_id, null) as i
	where s.login_name <> 'NT AUTHORITY\SYSTEM' 
		and s.session_id <> @@spid 
		and s.[status] <> 'dormant'
		and [host_name] <> 'DETIC-PA300-5B'
	order by s.[status] asc, s.last_request_start_time desc