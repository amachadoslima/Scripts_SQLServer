USE msdb
BEGIN

	SELECT 
			j.job_id AS JobID,
			j.[name] AS JobName,
			dp.[name] AS JobOwner,
			c.[name] AS JobCategory,
			j.[description] AS JobDescription,
			CASE j.[enabled]
				WHEN 1 THEN 'Yes'
				WHEN 0 THEN 'No'
			END AS IsEnabled,
			j.date_created AS JobCreatedOn,
			j.date_modified AS JobLastModifiedOn,
			s.[name] AS OriginatingServerName,
			js.step_id AS JobStartStepNo,
			js.step_name AS JobStartStepName,
			CASE
				WHEN sch.[schedule_uid] IS NULL THEN 'No'
				ELSE 'Yes'
			END AS IsScheduled,
			sch.schedule_uid AS JobScheduleID,
			sch.[name] AS JobScheduleName,
			CASE j.delete_level
				WHEN 0 THEN 'Never'
				WHEN 1 THEN 'On Success'
				WHEN 2 THEN 'On Failure'
				WHEN 3 THEN 'On Completion'
			END AS JobDeletionCriterion
		FROM sysjobs AS j
			LEFT JOIN sys.servers AS s ON j.originating_server_id = s.server_id
			LEFT JOIN syscategories AS c ON j.category_id = c.category_id
			LEFT JOIN sysjobsteps AS js	ON j.job_id = js.job_id AND j.start_step_id = js.step_id
			LEFT JOIN sys.database_principals AS dp ON j.owner_sid = dp.[sid]
			LEFT JOIN sysjobschedules AS jsh ON j.job_id = jsh.job_id
			LEFT JOIN sysschedules AS sch ON jsh.schedule_id = sch.schedule_id
		ORDER BY [JobName]

END