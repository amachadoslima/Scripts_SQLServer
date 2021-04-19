-- só pega requisições com status running
select 
		st.[text],
		r.session_id,
		r.[status],
		r.command,
		r.cpu_time,
		(d.memory_usage  * 8) as memory_usage_kb,
		(r.total_elapsed_time / 1000) as time_seconds_running,
		d.[host_name],
		d.[program_name],
		d.login_name,
		d.client_interface_name
	from sys.dm_exec_requests r
		join sys.dm_exec_sessions d on r.session_id = d.session_id 
		cross apply sys.dm_exec_sql_text([sql_handle]) as st
	where r.session_id not in (select @@spid) -- não mostra o session_id que está executando esta query.
	order by r.total_elapsed_time desc
	
	