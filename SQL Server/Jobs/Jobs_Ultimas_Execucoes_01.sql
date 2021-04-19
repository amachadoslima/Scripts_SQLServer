USE msdb 
GO
BEGIN

	SELECT 
			JobName = j.[name],
			StepID = s.step_id,
			StepName = s.step_name,
			StartDateTime = 
				CASE 
					WHEN jh1.[run_date] IS NULL OR jh1.[run_time] IS NULL THEN NULL
					ELSE CAST(CAST(jh1.[run_date] AS CHAR(8)) + ' ' + STUFF( STUFF(RIGHT('000000' + CAST(jh1.[run_time] AS VARCHAR(6)),  6), 3, 0, ':') , 6, 0, ':') AS DATETIME)
				END,
			RunStatus = 
				CASE jh1.[run_status]
					WHEN 0 THEN 'Failed'
					WHEN 1 THEN 'Succeeded'
					WHEN 2 THEN 'Retry'
					WHEN 3 THEN 'Canceled'
					WHEN 4 THEN 'Running' -- In Progress
				END,
			Duration = STUFF(STUFF(RIGHT('000000' + CAST(jh1.[run_duration] AS VARCHAR(6)),  6), 3, 0, ':') , 6, 0, ':'),
			[Message] = Cast(jh1.[message] as varchar(600))
		FROM sysjobs AS j
			LEFT JOIN (
				SELECT
						job_id,
						schedule_id,
						Min(next_run_date) AS NextRunDate,
						Min(next_run_time) AS NextRunTime
					FROM sysjobschedules
					GROUP BY job_id, schedule_id
			) AS jsch ON j.job_id = jsch.job_id
			LEFT JOIN sysschedules AS sch ON sch.schedule_id = jsch.schedule_id      
			LEFT JOIN sysjobhistory as jh1 ON j.job_id = jh1.job_id
			JOIN (
				SELECT 
						job_id, 
						Max(dbo.agent_datetime(run_date, run_time)) AS JobDateTime
					FROM sysjobhistory
					WHERE step_id = 0 
					GROUP BY job_id
			) jh ON j.job_id = jh.job_id
			JOIN sysjobsteps s ON s.job_id = j.job_id AND s.step_id = jh1.step_id
		WHERE  jh1.[run_status] <> 0 
			AND j.[enabled] = 1
			AND sch.[enabled] = 1
			AND dbo.agent_datetime(jh1.run_date, jh1.run_time) >= jh.jobdatetime
		ORDER BY j.[name], jh1.step_id ASC

END