USE msdb 
GO
BEGIN

	SET DATEFORMAT YMD;

	SELECT 
			JobName = j.[name],
			Setp = s.step_id,
			SetpName = s.step_name,
			RunDateTime = dbo.agent_datetime(run_date, run_time),
			RunDurationMinutes= Convert(VARCHAR(15), Cast(Stuff(Stuff(Replace(Str(run_duration, 7, 0), ' ', '0'), 4, 0,':'), 7, 0, ':') AS DATETIME), 114),
			[Message] = h.[message], 
			run_status
		FROM sysjobs j 
			JOIN msdb.dbo.sysjobsteps s ON j.job_id = s.job_id
			JOIN msdb.dbo.sysjobhistory h ON s.job_id = h.job_id AND s.step_id = h.step_id AND h.step_id <> 0
		WHERE j.[enabled] = 1
			AND run_status = 0
			AND dbo.agent_datetime(run_date, run_time) > Convert(VARCHAR(10), GetDate() -1, 121)
		ORDER BY JobName ASC, RunDateTime DESC

END