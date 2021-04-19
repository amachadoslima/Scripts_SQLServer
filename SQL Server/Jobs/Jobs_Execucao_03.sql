use msdb
go
begin

	select 
			j.[name] as job_name,
			case when ja.job_id is not null and ja.stop_execution_date is null then 1 else 0 end as running,
			ja.run_requested_source,
			ja.start_execution_date as last_run_time,
			ja.next_scheduled_run_date as next_run_time,
			js.step_name as last_job_step,
			jh.retries_attempted as retry_attempt,
			case
				when ja.job_id is not null and ja.stop_execution_date is null then 'running'
				when jh.run_status = 0 then 'failed'
				when jh.run_status = 1 then 'succeeded'
				when jh.run_status = 2 then 'retry'
				when jh.run_status = 3 then 'cancelled'
			end as job_last_out_come
		from sysjobs j
			left join sysjobactivity ja on ja.job_id = j.job_id and ja.run_requested_date is not null and ja.start_execution_date is not null
			left join sysjobsteps js on js.job_id = ja.job_id and js.step_id = ja.last_executed_step_id
			left join sysjobhistory jh on jh.job_id = j.job_id and jh.instance_id = ja.job_history_id
		where ja.job_id is not null 
			and ja.stop_execution_date is null
		order by ja.start_execution_date desc

end