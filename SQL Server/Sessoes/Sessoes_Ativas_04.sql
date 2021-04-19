with isolevels (transaction_isolation_level, isolation_level_name) as 
(
	select 0, 'unspecified' union all
	select 1, 'read uncomitted' union all
	select 2, 'read committed' union all
	select 3, 'repeatable' union all
	select 4, 'serializable' union all
	select 5, 'snapshot'
)
select
		r.percent_complete,
		s.[host_name],
		db_name(r.database_id) as 'database_name',
		(case when s.[program_name] like 'sqlagent - tsql jobstep (job %' then j.name else s.[program_name] end) as [name],
		s.login_name,
		r.[status],
		r.command,
		i.isolation_level_name,
		st.[text],
		r.blocking_session_id,
		r.session_id,
		r.wait_type,
		r.wait_time,
		isnull(datediff(mi, s.last_request_start_time, getdate()), 0) [minutesrunning],
		qp.query_plan
	from sys.dm_exec_requests r with (nolock)
		join sys.dm_exec_sessions s with (nolock) on r.session_id = s.session_id
		join isolevels i on s.transaction_isolation_level = i.transaction_isolation_level
		outer apply sys.dm_exec_sql_text(r.[sql_handle]) st
		outer apply sys.dm_exec_query_plan (r.plan_handle) as qp
		left outer join msdb.dbo.sysjobs j with (nolock) on	(substring(left(j.job_id, 8), 7, 2) + substring(left(j.job_id, 8), 5, 2) + substring(left(j.job_id, 8), 3, 2) 
					+ substring(left(j.job_id, 8), 1, 2))  = substring(s.program_name, 32, 8)
	where r.session_id > 50
		and r.session_id <> @@spid
		and s.[host_name] is not null
	order by s.[host_name], s.login_name