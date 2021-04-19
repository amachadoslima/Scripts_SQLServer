use master
go
select
		s.session_id,
		s.login_time,
		s.last_request_start_time,
		s.last_request_end_time,
		s.is_user_process,
		s.[host_name],
		s.[program_name],
		s.login_name,
		s.[status],
		c.num_reads,
		c.num_writes,
		c.last_read,
		c.last_write,
		s.reads,
		s.logical_reads,
		s.writes,
		t.databasename,
		t.objname,
		s.client_interface_name,
		s.nt_domain,
		s.nt_user_name,
		c.client_net_address,
		c.local_net_address,
		t.query,
		'kill '+ cast(s.session_id as varchar) + ';' as kill_command
	from sys.dm_exec_sessions as s
		join sys.dm_exec_connections as c on c.session_id = s.session_id
		cross apply (
			select db_name([dbid]) as databasename, object_name(objectid) as objname, coalesce((
					select [text] as [processing-instruction(definition)]
						from sys.dm_exec_sql_text(c.most_recent_sql_handle)
					for xml path(''), type), '') as query
				from sys.dm_exec_sql_text(c.most_recent_sql_handle)) t
	where s.session_id <> @@spid
		--and login_name = 'SDBP12'
	order by s.last_request_start_time desc