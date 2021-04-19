SELECT 
		Avg(current_tasks_count) AS [Avg Current Task],
		Avg(runnable_tasks_count) AS [Avg Wait Task]
	FROM sys.dm_os_schedulers
	WHERE scheduler_id < 255
		AND [status] = 'VISIBLE ONLINE'
GO
SELECT
		scheduler_id AS SchedulerID,
		current_tasks_count AS CurrentTasksCount,
		runnable_tasks_count AS RunnableTasksCount
	FROM sys.dm_os_schedulers
	WHERE scheduler_id < 255
		AND runnable_tasks_count > 0
GO
SELECT
		t.task_state AS TaskState,
		r.session_id AS SessionID,
		s.context_switches_count AS ContextSwitchesCount,
		s.pending_disk_io_count As PendingDiskIO,
		s.scheduler_id AS CPUId,
		s.[status] AS SchedulerStatus,
		DB_Name(r.database_id) AS DBName,
		r.command As Command,
		px.[text] AS SQLText
	FROM sys.dm_os_schedulers as s
		JOIN sys.dm_os_tasks t on s.active_worker_address = t.worker_address
		JOIN sys.dm_exec_requests r on t.task_address = r.task_address
		CROSS APPLY sys.dm_exec_sql_text(r.plan_handle) as px
	WHERE r.session_id <> @@SPID
		--AND s.scheduler_id < 255
		--AND t.task_state = 'RUNNABLE'