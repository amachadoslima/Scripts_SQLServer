USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY
	
	DECLARE @YieldCount TABLE
	(
		scheduler_id	VARBINARY(8),
		yield_count		INT
	)

	INSERT INTO @YieldCount
		SELECT scheduler_id, yield_count 
			FROM sys.dm_os_schedulers
			WHERE scheduler_id < 255

	SELECT 
			COUNT(1) AS [Count],
			CASE 
				WHEN s.work_queue_count > 0 THEN 
					CASE 
						WHEN s.yield_count = y.yield_count THEN 'Hung'
						ELSE 'Active'
					END
				ELSE 'Idle'
			END AS [Status]
		FROM sys.dm_os_schedulers s
			JOIN @YieldCount y ON s.scheduler_id = y.scheduler_id
		GROUP BY 
			CASE 
				WHEN s.work_queue_count > 0 THEN 
					CASE 
						WHEN s.yield_count = y.yield_count THEN 'Hung'
						ELSE 'Active'
					END
				ELSE 'Idle'
			END

END TRY
BEGIN CATCH
	SELECT 
		ERROR_NUMBER() AS ERR_NUM,
		ERROR_SEVERITY() AS ERR_SVR,
		ERROR_STATE() AS ER_STT,
		ERROR_MESSAGE() AS ER_STS
END CATCH
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

	DECLARE @YieldCount TABLE
	(
		scheduler_id	VARBINARY(8),
		yield_count		INT
	)

	DECLARE @SchedulerHealthTable TABLE 
	(
		rank_no						INT IDENTITY,
		[status]					VARCHAR(10) COLLATE DATABASE_DEFAULT,
		scheduler_id				INT,
		cpu_id						SMALLINT,
		is_online					SMALLINT,
		preemptive_switches_count	INT,
		context_switches_count		INT,
		idle_switches_count			INT,
		current_tasks_count			INT,
		runnable_tasks_count		INT,
		current_workers_count		INT,
		active_workers_count		INT,
		work_queue_count			BIGINT,
		pending_disk_io				INT,
		load_factor					INT,
		is_preemptive				BIT,
		is_fiber					BIT,
		context_switch_count		INT,
		io_count					INT,
		[state]						VARCHAR(20) COLLATE DATABASE_DEFAULT,
		memory						INT,
		worker_address				VARBINARY(8),
		task_address				VARBINARY(8),
		spid						INT,
		proc_status					VARCHAR(20) COLLATE DATABASE_DEFAULT,
		hostname					NVARCHAR(128) COLLATE DATABASE_DEFAULT,
		[program_name]				NVARCHAR(128) COLLATE DATABASE_DEFAULT,
		text1						VARCHAR(5000) COLLATE DATABASE_DEFAULT,
		task_ctx					INT,
		task_io						INT,
		worker_address_string		VARCHAR(18) COLLATE DATABASE_DEFAULT,
		task_address_string			VARCHAR(18) COLLATE DATABASE_DEFAULT
	)

	INSERT INTO @YieldCount
		SELECT scheduler_id, yield_count 
			FROM sys.dm_os_schedulers
			WHERE scheduler_id < 255

	INSERT INTO @SchedulerHealthTable
		SELECT 
				CASE 
					WHEN S.work_queue_count = 0 THEN 'Idle'
					ELSE 
						CASE 
							WHEN S.yield_count = Y.yield_count THEN 'Hung'
							ELSE 'Active'
						END
				END AS [status],
				S.scheduler_id,
				S.cpu_id,
				is_online,
				S.preemptive_switches_count,
				S.context_switches_count,
				S.idle_switches_count,
				S.current_tasks_count,
				S.runnable_tasks_count,
				S.current_workers_count,
				S.active_workers_count,
				S.work_queue_count,
				S.pending_disk_io_count,
				S.load_factor,
				W.is_preemptive,
				W.is_fiber,
				W.context_switch_count,
				W.pending_io_count,
				W.[state],
				M.page_size_in_bytes * M.max_pages_allocated_count AS memory,
				W.worker_address,
				W.task_address,
				T.session_id,
				req.[status] AS req_status,
				[sessions].[host_name],
				[sessions].[program_name],
				CASE 
					WHEN req.[sql_handle] IS NOT NULL THEN(SELECT TOP 1 SubString(t2.[text], (req.statement_start_offset + 2) / 2, ((
						CASE 
							WHEN req.statement_end_offset = -1 THEN (Len(Convert(NVARCHAR(MAX), t2.[text])) * 2) 
							ELSE req.statement_end_offset 
						END)  - req.statement_start_offset) / 2) FROM sys.dm_exec_sql_text(req.[sql_handle]) t2 ) 
					ELSE '' 
				END AS text1,
				T.context_switches_count AS task_ctx,
				T.pending_io_count AS task_io,
				master.dbo.fn_varbintohexstr(W.worker_address),
				master.dbo.fn_varbintohexstr(W.task_address)
			FROM sys.dm_os_schedulers S
				JOIN @YieldCount Y ON (S.scheduler_id = Y.scheduler_id)
				LEFT OUTER JOIN sys.dm_os_workers W  ON (S.scheduler_address = W.scheduler_address)
				LEFT OUTER JOIN sys.dm_os_memory_objects M ON (W.memory_object_address = M.memory_object_address)
				LEFT OUTER JOIN sys.dm_os_tasks T ON (W.task_address = T.task_address)
				LEFT OUTER JOIN sys.dm_exec_sessions [sessions] ON (T.session_id  = [sessions].session_id)
				LEFT OUTER JOIN sys.dm_exec_requests req ON (req.task_address = W.task_address)

	SELECT *
		FROM @SchedulerHealthTable
		ORDER BY [status], scheduler_id, cpu_id

END TRY
BEGIN CATCH
	SELECT 
		-100 AS l1,
		1 AS l2,
		1 AS l3,
		1 AS rank_no,
		1 AS [status],
		1 AS scheduler_id,
		1 AS cpu_id,
		1 AS is_online,
		1 AS preemptive_switches_count,
		1 AS context_switches_count,
		1 AS idle_switches_count,
		1 AS current_tasks_count,
		1 AS runnable_tasks_count,
		1 AS current_workers_count,
		1 AS active_workers_count,
		1 AS work_queue_count,
		1 AS pending_disk_io,
		1 AS load_factor,
		1 AS is_preemptive,
		1 AS is_fiber,
		1 AS context_switch_count,
		1 AS io_count,
		1 AS [state],
		1 AS memory,
		1 AS worker_address,
		1 AS task_address,
		1 AS spid,
		1 AS proc_status,
		1 AS hostname, 1 AS [program_name],
		1 AS text1,
		ERROR_NUMBER() AS task_ctx,
		ERROR_SEVERITY() AS task_io,
		ERROR_STATE() AS worker_address_string,
		ERROR_MESSAGE() AS task_address_string
END CATCH