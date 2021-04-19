use master
go
select
		s.[host_name],
		s.login_name,
		r.session_id,
		cast(r.percent_complete as decimal(10,5)) as [percent],
		isnull(datediff(minute, s.last_request_start_time, getdate()), 0) [minutes_running],
		start_time,
		dateadd(second, estimated_completion_time / 1000, getdate()) as [estimated_completion],
		db_name(r.database_id) as [database_name],
		(case when s.program_name like 'sqlagent - tsql jobstep (job %' then j.[name] else s.program_name end) as [program_name],
		r.command,
		b.[text]
	from sys.dm_exec_requests r with (nolock)
		join sys.dm_exec_sessions s with (nolock) on r.session_id = s.session_id
		outer apply sys.dm_exec_sql_text(r.sql_handle) b
		left outer join msdb.dbo.sysjobs j with (nolock) on (substring(left(j.job_id, 8), 7, 2) + substring(left(j.job_id, 8), 5, 2) +
						substring(left(j.job_id, 8), 3, 2) + substring(left(j.job_id, 8), 1, 2)) = substring(s.program_name, 32, 8)
	where
		r.session_id > 50
		and r.session_id <> @@spid
		and s.[host_name] is not null
		and lower(r.command) like '%restore%'
	order by s.[host_name], s.login_name