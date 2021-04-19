use msdb
go
begin

	if(object_id(N'tempdb..#tmpJob') is not null)
		drop table #tmpJob

	create table #tmpJob
	(
		job_id uniqueidentifier,
		last_run_date int,
		last_run_time int,
		next_run_date int,
		next_run_time int,
		next_run_schedule_id int,
		request_to_run int,
		requested_to_run int,
		request_source_id varchar(100),
		running int,
		current_step int,
		current_retry_attempt int,
		[state] int
	)

	
    insert into #tmpjob 
         exec master.dbo.xp_sqlagent_enum_jobs 1, garbage

    select 
			--tmp.*, j.[name] as job_name, s.step_name
			tmp.job_id,
			j.[name] as job_name, 
			s.step_name,
			tmp.running,
			tmp.current_step,
			dateadd(second, (tmp.last_run_time / 10000 * 3600) + (((tmp.last_run_time % 10000 - tmp.last_run_time % 100) / 100) * 60) + 
						    (tmp.last_run_time % 100), convert(datetime, cast(nullif(tmp.last_run_date, 0) as nvarchar(10)))) as [last_run_datetime],
			dateadd(second, (tmp.next_run_time / 10000 * 3600) + (((tmp.next_run_time % 10000 - tmp.next_run_time % 100) / 100) * 60) + 
						    (tmp.next_run_time % 100), convert(datetime, cast(nullif(tmp.next_run_date, 0) as nvarchar(10)))) as [next_run_datetime]
		from #tmpjob as tmp
			join sysjobs as j on j.job_id = tmp.job_id
			join sysjobsteps as s on s.job_id = j.job_id and s.step_id = tmp.current_step

	if(object_id(N'tempdb..#tmpJob') is not null)
		drop table #tmpJob

end

