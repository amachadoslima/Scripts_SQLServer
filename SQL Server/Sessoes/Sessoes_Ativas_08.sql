SET NOCOUNT ON

If(Object_ID(N'tempdb..#tmpBlockers') IS NOT NULL)
	DROP TABLE #tmpBlockers

DECLARE @WaitThreshold INT = 30 -- Segundos
DECLARE @ServerVersion INT

Set @ServerVersion = Replace(Left(Convert(VARCHAR, ServerProperty('ProductVersion')), 2), '.', '')

SELECT
		SessionID = S.session_id,
		HeadBlocker = CASE WHEN R.blocking_session_id IS NULL OR R.blocking_session_id = 0 THEN 'TRUE' ELSE 'FALSE' END,
		BlockingSessionID = R.blocking_session_id,
		RequestStatus = R.[status],
		SessionStatus = S.[status],
		SqlStmnt = Cast(Left(
			CASE R.[sql_handle]
				WHEN NULL THEN (SELECT [text] FROM sys.dm_exec_sql_text(R.[sql_handle]))
				ELSE (SELECT [text] FROM sys.dm_exec_sql_text(C.most_recent_sql_handle)) 
			END, 4000) AS NVARCHAR(4000)),
		ProgramName = S.[program_name],
		HostName = S.[host_name],
		HostProcessID = S.host_process_id,
		LoginName = S.login_name,
		LoginTime = S.login_time,
		RequestStartTime = R.start_time,
		WaitType = R.wait_type,
		LastWaitType = R.last_wait_type,
		WaitTimeSec = (R.wait_time / 1000),
		Command = R.command,
		WaitResource = R.wait_resource,
		TransIsolationLevel = 
			CASE Coalesce(R.transaction_isolation_level, S.transaction_isolation_level)
				WHEN 0 THEN 'UNSPECIFIED'
				WHEN 1 THEN 'READ UNCOMMITTED'
				WHEN 2 THEN 'READ COMMITTED'
				WHEN 3 THEN 'REPEATABLE'
				WHEN 4 THEN 'SERIALIZABLE' 
				WHEN 5 THEN 'SNAPSHOT' 
				ELSE Convert(VARCHAR(10), Coalesce(R.transaction_isolation_level, S.transaction_isolation_level)) + '-Unknown' 
			END,
		OpenTransCount = R.open_transaction_count,
		OpenResultSetCount = R.open_resultset_count,
		PercentComplete = Convert(DECIMAL(10, 5), R.percent_complete),
		EstimatedCompletionTime = R.estimated_completion_time,
		RequestLogicalReads = 
			CASE 
				WHEN (@ServerVersion > 9) OR (@ServerVersion = 9 AND ServerProperty('ProductLevel') >= 'SP2' COLLATE Latin1_General_BIN) THEN R.logical_reads 
				ELSE R.logical_reads - S.logical_reads 
			END,  
		RequestReads = 
			CASE 
				WHEN (@ServerVersion > 9) OR (@ServerVersion = 9 AND ServerProperty('ProductLevel') >= 'SP2' COLLATE Latin1_General_BIN) THEN R.reads 
				ELSE R.reads - S.reads 
			END,  
		RequestWrites = 
			CASE 
				WHEN (@ServerVersion > 9) OR (@ServerVersion = 9 AND ServerProperty('ProductLevel') >= 'SP2' COLLATE Latin1_General_BIN) THEN R.writes 
				ELSE R.writes - S.writes 
			END,
		RequestCPUTime = R.cpu_time,
		LockTimeout = R.[lock_timeout],
		DeadlockPriority = R.[deadlock_priority],
		RequestRowCount = R.row_count,
		RequestPrevError = R.prev_error,
		NestLevel = R.nest_level, 
		GrantedQueryMemory = R.granted_query_memory, 
		UserID = R.[user_id], 
		TransactioID = R.transaction_id, 
		SessionCPUTime = S.cpu_time, 
		MemoryUsage = S.memory_usage, 
		SessionReads = S.reads,
		SessionLogicalReads= S.logical_reads, 
		SessionWrites= S.writes, 
		SessionPrevError = S.prev_error, 
		SessionRowCount = S.row_count
	INTO #tmpBlockers
	FROM sys.dm_exec_sessions S
		LEFT OUTER JOIN sys.dm_exec_requests R ON R.session_id = S.session_id
		LEFT OUTER JOIN sys.dm_exec_connections C ON C.session_id = S.session_id
	WHERE S.session_id >= 50

SELECT * FROM #tmpBlockers

If(Object_ID(N'tempdb..#tmpBlockers') IS NOT NULL)
	DROP TABLE #tmpBlockers