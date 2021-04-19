USE msdb 
GO
BEGIN

	;WITH JOBS AS
	(
		SELECT
				J.job_id,
				Convert(VARCHAR(15), Cast(Stuff(Stuff(Replace(Str(run_duration, 7, 0), ' ', '0'), 4, 0,':'), 7, 0, ':') AS DATETIME), 114) AS Last_Dur, 
				Convert(DATETIME, RTrim(run_date) + ' ' + Stuff(Stuff(Replace(Str(RTrim(H2.run_time), 6, 0), ' ', '0'), 3, 0, ':'), 6, 0, ':')) AS [Start_Date]
			FROM sysjobs J
				JOIN(
					SELECT job_id, instance_id = Max(instance_id) 
						FROM sysjobhistory 
						GROUP BY job_id) AS H1 ON J.job_id = H1.job_id
				JOIN sysjobhistory AS H2 on H2.job_id = H1.job_id and H2.instance_id = H1.instance_id
	),
	SPIDS AS
	(
		SELECT DISTINCT 
				Left([Value], CharIndex(':', [Value]) - 1) AS JobID,
				SubString([Value], CharIndex(':', [Value]) + 1, CharIndex(')', [Value]) - CharIndex(':', [Value]) - 1) AS Step,
				spid AS [SPID]
			FROM master.dbo.sysprocesses X
				CROSS APPLY (SELECT Replace(X.[program_name], 'SQLAGENT - TSQL JOBSTEP (JOB ', '')) CS([Value])
			WHERE spid> 50
				AND X.[program_name] LIKE 'sqlagent - tsql jobstep (job %'
    )
	SELECT
			JA.job_id,
			S.SPID,
			J.[name] as JobName,
			IsNull(last_executed_step_id, 0) + 1 AS CurrentExecutedStepID,
			JS.step_name AS StepName,
			JA.start_execution_date AS StartExecutionDate,
			Convert(VARCHAR(15), DateAdd(SECOND, (DateDiff(SECOND, JA.start_execution_date, GetDate())), '1900-01-01'), 114) AS DurTime,
			CJ.Last_Dur AS [LastDur],
			CJ.[Start_Date] AS LastRun
		FROM sysjobactivity JA
			LEFT JOIN sysjobhistory JH on JA.job_history_id = JH.instance_id
			JOIN sysjobs J ON JA.job_id = J.job_id
			JOIN sysjobsteps JS ON JA.job_id = JS.job_id and isnull(JA.last_executed_step_id, 0 ) + 1 = JS.step_id
			LEFT JOIN JOBS CJ ON JA.job_id = CJ.job_id
			LEFT JOIN SPIDS S ON S.JobID = Convert(VARCHAR(MAX), Convert(BINARY (16), J.job_id), 1)
		WHERE JA.session_id = (
				SELECT TOP 1 session_id 
					FROM syssessions 
					ORDER BY agent_start_date DESC
			)
			AND start_execution_date IS NOT NULL
			AND stop_execution_date IS NULL
		ORDER BY DurTime DESC

end