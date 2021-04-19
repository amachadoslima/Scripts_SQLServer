USE msdb 
GO

SET NOCOUNT ON

DECLARE @JobName VARCHAR(300)
DECLARE @JobID UNIQUEIDENTIFIER

Set @JobName = 'Sigero - Followup - Processar Rateio'

SELECT @JobID = job_id
	FROM sysjobs
	WHERE [name] = @JobName

SELECT 
		sj.[name],
		Left(sh.run_date, 4) + '-' + SubString(Cast(sh.run_date AS VARCHAR), 5, 2) + '-' + Right(sh.run_date, 2) + ' ' +
			Stuff(Stuff(Right(Replicate('0', 6) +  CAST(sh.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':') as run,
		sh.step_name,
		Stuff(Stuff(Stuff(Right(Replicate('0', 8) + CAST(sh.run_duration AS VARCHAR(8)), 8), 3, 0, ':'), 6, 0, ':'), 9, 0, ':') 'run_duration'
	FROM msdb.dbo.sysjobs sj
		JOIN msdb.dbo.sysjobhistory sh ON sj.job_id = sh.job_id
	WHERE sj.job_id = @JobID
	ORDER BY 1 ASC, 2 DESC