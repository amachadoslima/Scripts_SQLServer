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
		a.session_id,
		b.reads,
		b.logical_reads,
		b.[host_name],
		db_name(a.database_id) as 'database_name',
		(case when b.program_name like 'sqlagent - tsql jobstep (job %' then f.[name] else b.program_name end) as [name],
		b.login_name,
		a.[status],
		a.command,
		c.isolation_level_name,
		d.[text],
		a.blocking_session_id,
		a.wait_type,
		a.wait_time,
		isnull(datediff(mi, b.last_request_start_time, getdate()), 0) [minutesrunning],
		e.query_plan
	from sys.dm_exec_requests a with (nolock) 
		join sys.dm_exec_sessions b with (nolock) on a.session_id = b.session_id
		join isolevels c on b.transaction_isolation_level = c.transaction_isolation_level
		outer apply sys.dm_exec_sql_text(a.[sql_handle]) d 
		outer apply sys.dm_exec_query_plan (a.plan_handle) as e
		left outer join msdb.dbo.sysjobs f with (nolock) on	(substring(left(f.job_id, 8), 7, 2) + substring(left(f.job_id, 8), 5, 2) + substring(left(f.job_id, 8), 3, 2) 
							+ substring(left(f.job_id, 8), 1, 2))  = substring(b.program_name, 32, 8)
	where a.session_id > 50
		and a.session_id <> @@spid
		and b.[host_name] is not null
	order by b.reads, b.logical_reads

