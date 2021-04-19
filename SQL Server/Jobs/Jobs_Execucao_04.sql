USE msdb 
GO
BEGIN

	;WITH JOBS AS
	(
		SELECT
				J.job_id,
				Last_Dur = Convert(VARCHAR(15), Cast(Stuff(Stuff(Replace(Str(run_duration, 7, 0), ' ', '0'), 4, 0,':'), 7, 0, ':') AS DATETIME), 114), 
				[Start_Date] = Convert(DATETIME, RTrim(run_date) + ' ' + Stuff(Stuff(Replace(Str(RTrim(H2.run_time), 6, 0), ' ', '0'), 3, 0, ':'), 6, 0, ':'))
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
				JobID = Left([Value], CharIndex(':', [Value]) - 1),
				Step = SubString([Value], CharIndex(':', [Value]) + 1, CharIndex(')', [Value]) - CharIndex(':', [Value]) - 1),
				[SPID] = spid
			FROM master.dbo.sysprocesses X
				CROSS APPLY (SELECT Replace(X.[program_name], 'SQLAGENT - TSQL JOBSTEP (JOB ', '')) CS([Value])
			WHERE spid> 50
				AND X.[program_name] LIKE 'sqlagent - tsql jobstep (job %'
    )
	SELECT
			JobID = JA.job_id,
			S.SPID,
			[PerComplete] = CASE R.percent_complete WHEN 0 THEN NULL ELSE R.percent_complete END,
			JobName = J.[name],
			StepName = JS.step_name + ' (Step: ' + Convert(VARCHAR, IsNull(last_executed_step_id, 0) + 1) + ')',
			StartExecutionDate = JA.start_execution_date,
			DurTime = Convert(VARCHAR(15), DateAdd(SECOND, (DateDiff(SECOND, JA.start_execution_date, GetDate())), '1900-01-01'), 114),
			[LastDur]= CJ.Last_Dur,
			LastRun = CJ.[Start_Date],
			EstimatedCompletion = DateAdd(SECOND, estimated_completion_time / 1000, GetDate()) 
		FROM sysjobactivity JA
			LEFT JOIN sysjobhistory JH on JA.job_history_id = JH.instance_id
			JOIN sysjobs J ON JA.job_id = J.job_id
			JOIN sysjobsteps JS ON JA.job_id = JS.job_id and isnull(JA.last_executed_step_id, 0 ) + 1 = JS.step_id
			LEFT JOIN JOBS CJ ON JA.job_id = CJ.job_id
			LEFT JOIN SPIDS S ON S.JobID = Convert(VARCHAR(MAX), Convert(BINARY (16), J.job_id), 1)
			LEFT JOIN sys.dm_exec_requests R ON R.session_id = S.SPID
		WHERE JA.session_id = (
				SELECT TOP 1 session_id 
					FROM syssessions 
					ORDER BY agent_start_date DESC
			)
			AND start_execution_date IS NOT NULL
			AND stop_execution_date IS NULL
		ORDER BY StartExecutionDate ASC

END