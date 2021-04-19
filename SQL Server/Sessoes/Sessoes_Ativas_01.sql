--select @@spid as [spid]
select
		s.login_name,
		r.session_id as 'spid',
		r.start_time,
		db_name(r.database_id) as db,
		r.command,
		st.[text],
		substring(st.[text], r.statement_start_offset / 2 + 1,
			(case 
				when r.statement_end_offset = -1 then len(convert(nvarchar(max), st.text)) * 2
				else r.statement_end_offset end - r.statement_start_offset) / 2 + 1) as 'offset',
		r.blocking_session_id, 
		r.wait_type,
		r.last_wait_type,
		r.cpu_time,
		r.total_elapsed_time,
		r.reads,
		r.writes,
		s.memory_usage,
		s.[host_name],
		s.[program_name]
	from sys.dm_exec_requests r
		join sys.dm_exec_connections c on r.session_id = c.session_id
		join sys.dm_exec_sessions s on s.session_id = r.session_id 
		cross apply sys.dm_exec_sql_text(r.[sql_handle]) st 
	where r.session_id > 50
		and r.session_id <> @@spid 
	order by r.session_id