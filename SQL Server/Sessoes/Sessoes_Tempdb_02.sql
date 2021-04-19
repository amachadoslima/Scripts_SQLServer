if object_id('tempdb..##tmp') is not null
  drop table ##tmp

if object_id('tempdb..##tmp2') is not null
  drop table ##tmp2

select distinct p.spid, j.[name] as jobname
	into ##tmp
	from master.dbo.sysprocesses p 
		join msdb.dbo.sysjobs j on master.dbo.fn_varbintohexstr(convert(varbinary(16), job_id)) = substring(replace(program_name, 'sqlagent - tsql jobstep (job ', ''), 1, 34)

;with tempdb_usage as (
    select 
		session_id,
		request_id,
		sum(internal_objects_alloc_page_count) as alloc_pages,
		sum(internal_objects_dealloc_page_count) as dealloc_pages
    from sys.dm_db_task_space_usage with (nolock)
    where session_id <> @@spid
    group by session_id, request_id
)
select 
		a.session_id,
		c.login_name,
		(a.alloc_pages * 1.0 / 128) as mb_space,
		a.dealloc_pages * 1.0 / 128 as dalloc_mb_space,
		d.[text],
		   isnull(
			   nullif(
				   substring(d.[text], b.statement_start_offset / 2, 
					case when b.statement_end_offset < b.statement_start_offset then 0 else(b.statement_end_offset - b.statement_start_offset ) / 2 end), ''
			   ), d.text
		   ) as strtext,
		   e.query_plan,
		   c.reads, 
		   c.writes
	into ##tmp2
	from tempdb_usage as a 
		join sys.dm_exec_requests b with (nolock) on a.session_id = b.session_id and a.request_id = b.request_id
		join sys.dm_exec_sessions c on a.session_id = c.session_id
		outer apply sys.dm_exec_sql_text(b.sql_handle) as d
		outer apply sys.dm_exec_query_plan(b.plan_handle) as e
	where d.text is not null 
		or e.query_plan is not null
	order by 3 desc;


select 
		a.session_id, 
		a.login_name,
		isnull(b.jobname, 'n/a') as job_name,	 
		a.mb_space, 
		a.dalloc_mb_space, 
		a.[text], 
		a.strtext, 
		a.query_plan,
		a.reads,
		a.writes
	from ##tmp2 a 
		left outer join ##tmp b on a.session_id = b.spid
	where (a.mb_space + a.dalloc_mb_space) > 0
