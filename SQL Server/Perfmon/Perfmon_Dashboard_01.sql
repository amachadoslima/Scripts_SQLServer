BEGIN 

	DECLARE @SQLProcessUtilization		INT
	DECLARE @PageReadsPerSecond			BIGINT
	DECLARE @PageWritesPerSecond		BIGINT
	DECLARE @CheckpointPagesPerSecond	BIGINT
	DECLARE @LazyWritesPerSecond		BIGINT
	DECLARE @BatchRequestsPerSecond		BIGINT
	DECLARE @CompilationsPerSecond		BIGINT
	DECLARE @ReCompilationsPerSecond	BIGINT
	DECLARE @PageLookupsPerSecond		BIGINT
	DECLARE @TransactionsPerSecond		BIGINT
	DECLARE @StartDate					DATETIME

	IF(OBJECT_ID(N'tempdb..#RatioStatsX') IS NOT NULL)
		DROP TABLE #RatioStatsX

	IF(OBJECT_ID(N'tempdb..#RatioStatsY') IS NOT NULL)
		DROP TABLE #RatioStatsY


	-- Tabela para nosso primeiro exemplo
	CREATE TABLE #RatioStatsX
	(
		[object_name]	VARCHAR(128),
		[counter_name]	VARCHAR(128),
		[instance_name]	VARCHAR(128),
		[cntr_value]	BIGINT,
		[cntr_type]		INT
	)

	-- Tabela para nosso segundo exemplo
	CREATE TABLE #RatioStatsY
	(
		[object_name]	VARCHAR(128),
		[counter_name]	VARCHAR(128),
		[instance_name]	VARCHAR(128),
		[cntr_value]	BIGINT,
		[cntr_type]		INT
	)

	INSERT INTO #RatioStatsX 
		SELECT 
			[object_name],
			[counter_name],
			[instance_name],
			[cntr_value],
			[cntr_type] 
		FROM sys.dm_os_performance_counters

	Set @StartDate = GetDate()

	SELECT TOP 1 @PageReadsPerSecond = cntr_value
		FROM #RatioStatsX
		WHERE counter_name = 'Page reads/sec'
			AND [object_name] = 
				CASE 
					WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager'
					ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
				END

	SELECT TOP 1 @PageWritesPerSecond = cntr_value
		FROM #RatioStatsX
		WHERE counter_name = 'Page writes/sec'
			AND [object_name] = 
				CASE 
					WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager'
					ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
				END

	SELECT TOP 1 @CheckpointPagesPerSecond = cntr_value
		FROM #RatioStatsX
		WHERE counter_name = 'Checkpoint pages/sec'
			AND [object_name] = 
				CASE 
					WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager'
					ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
				END

	SELECT TOP 1 @LazyWritesPerSecond = cntr_value
		FROM #RatioStatsX
		WHERE counter_name = 'Lazy writes/sec'
			AND [object_name] = 
				CASE 
					WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager'
					ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
				END

	SELECT TOP 1 @BatchRequestsPerSecond = cntr_value
		FROM #RatioStatsX
		WHERE counter_name = 'Batch Requests/sec'
		AND [object_name] = 
			CASE
				WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:SQL Statistics'
				ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':SQL Statistics' 
			END
	
	SELECT TOP 1 @CompilationsPerSecond = cntr_value
		FROM #RatioStatsX
		WHERE counter_name = 'SQL Compilations/sec'
			AND [object_name] = 
				CASE 
					WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:SQL Statistics'
					ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':SQL Statistics' 
				END
	
	SELECT TOP 1 @ReCompilationsPerSecond = cntr_value
		FROM #RatioStatsX
		WHERE counter_name = 'SQL Re-Compilations/sec'
			AND [object_name] = 
				CASE
					WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:SQL Statistics'
					ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':SQL Statistics' 
				END
	
	SELECT TOP 1 @PageLookupsPerSecond=cntr_value
		FROM #RatioStatsX
		WHERE counter_name = 'Page lookups/sec'
			AND [object_name] = 
				CASE 
					WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager'
					ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
				END
	
	SELECT TOP 1 @TransactionsPerSecond=cntr_value
		FROM #RatioStatsX
		WHERE counter_name = 'Transactions/sec' 
			AND instance_name = '_Total'
			AND [object_name] = 
				CASE 
					WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Databases'
					ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Databases' 
				END
	
	-- Espera 5 segundos para iniciar a segunda coleta
	WAITFOR DELAY '00:00:05'

	-- Tabela relacionada a segunda coleta
	INSERT INTO #RatioStatsY 
		SELECT 
				[object_name],
				[counter_name],
				[instance_name],
				[cntr_value],
				[cntr_type]
			FROM sys.dm_os_performance_counters

	SELECT
			(A.cntr_value * 1.0 / B.cntr_value) * 100.0 [BufferCacheHitRatio],
			C.[PageReadPerSec] [PageReadsPerSec],
			D.[PageWritesPerSecond] [PageWritesPerSecond],
			E.cntr_value [UserConnections],
			F.cntr_value [PageLifeExpectency],
			G.[CheckpointPagesPerSecond] [CheckpointPagesPerSecond],
			H.[LazyWritesPerSecond] [LazyWritesPerSecond],
			I.cntr_value [FreeSpaceInTempdbKB],
			J.[BatchRequestsPerSecond] [BatchRequestsPerSecond],
			K.[SQLCompilationsPerSecond] [SQLCompilationsPerSecond],
			L.[SQLReCompilationsPerSecond] [SQLReCompilationsPerSecond],
			M.cntr_value [Target Server Memory (KB)],
			N.cntr_value [Total Server Memory (KB)],
			GetDate() AS [MeasurementTime],
			O.[AvgTaskCount],
			O.[AvgRunnableTaskCount],
			O.[AvgPendingDiskIOCount],
			P.PercentSignalWait AS [PercentSignalWait],
			Q.PageLookupsPerSecond As [PageLookupsPerSecond],
			R.TransactionsPerSecond AS [TransactionsPerSecond],
			S.cntr_value [MemoryGrantsPending]
		FROM (
			SELECT *, 1 X
				FROM #RatioStatsY
				WHERE counter_name = 'Buffer cache hit ratio'
					AND [object_name] = 
						CASE 
							WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager' 
							ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
						END
			) A	
			JOIN
			(
				SELECT *, 1 X 
					FROM #RatioStatsY
					WHERE counter_name = 'Buffer cache hit ratio base'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
							END 
			) B	ON A.X = B.X
			JOIN
			(
				SELECT (cntr_value - @PageReadsPerSecond) / (
						CASE 
							WHEN DateDiff(ss, @StartDate, GetDate()) = 0 THEN 1 
							ELSE DateDiff(ss, @StartDate, GetDate()) 
						END) AS [PageReadPerSec], 1 X
					FROM #RatioStatsY
					WHERE counter_name = 'Page reads/sec'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
							END
			) C ON A.X = C.X
			JOIN
			(
				SELECT (cntr_value - @PageWritesPerSecond) / (
						CASE 
							WHEN DateDiff(ss, @StartDate, GetDate()) = 0 THEN 1 
							ELSE DateDiff(ss, @StartDate, GetDate()) 
						END) AS [PageWritesPerSecond], 1 X
					FROM #RatioStatsY
					WHERE counter_name = 'Page writes/sec'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
							END
			) D ON A.X = D.X
			JOIN
			(
				SELECT *, 1 X 
					FROM #RatioStatsY
					WHERE counter_name = 'User Connections'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:General Statistics' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':General Statistics' 
							END 
			) E	ON A.X = E.X
			JOIN
			(
				SELECT *, 1 X 
					FROM #RatioStatsY
					WHERE counter_name = 'Page life expectancy '
						AND [object_name] =
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
							END
			) F ON A.X = F.X
			JOIN
			(
				SELECT (cntr_value - @CheckpointPagesPerSecond) / (
						CASE 
							WHEN DateDiff(ss, @StartDate, GetDate()) = 0 THEN 1 
							ELSE DateDiff(ss, @StartDate, GetDate()) 
						END) AS [CheckpointPagesPerSecond], 1 X
					FROM #RatioStatsY
					WHERE counter_name = 'Checkpoint pages/sec'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
							END
			) G ON A.X = G.X
			JOIN
			(
				SELECT (cntr_value - @LazyWritesPerSecond) / (
						CASE 
							WHEN DateDiff(ss, @StartDate, GetDate()) = 0 THEN 1 
							ELSE DateDiff(ss, @StartDate, GetDate()) END) AS [LazyWritesPerSecond], 1 X
					FROM #RatioStatsY
					WHERE counter_name = 'Lazy writes/sec'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
							END
			) H ON A.X = H.X
			JOIN
			(
				SELECT *, 1 X 
					FROM #RatioStatsY
					WHERE counter_name = 'Free Space in tempdb (KB)'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Transactions' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Transactions' END
			) I ON A.X = I.X
			JOIN
			(
				SELECT (cntr_value - @BatchRequestsPerSecond) / (
						CASE 
							WHEN DateDiff(ss, @StartDate, GetDate()) = 0 THEN 1 
							ELSE DateDiff(ss, @StartDate, GetDate()) 
						END) AS [BatchRequestsPerSecond], 1 X
					FROM #RatioStatsY
					WHERE counter_name = 'Batch Requests/sec'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:SQL Statistics' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':SQL Statistics' 
							END
			) J	ON A.X = J.X
			JOIN
			(
				SELECT (cntr_value - @CompilationsPerSecond) / (
						CASE 
							WHEN DateDiff(ss, @StartDate,GetDate()) = 0 THEN 1 
							ELSE DateDiff(ss, @StartDate, GetDate()) 
						END) AS [SQLCompilationsPerSecond], 1 X
					FROM #RatioStatsY
					WHERE counter_name = 'SQL Compilations/sec'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:SQL Statistics' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':SQL Statistics' 
							END
			) K ON A.X = K.X
			JOIN
			(
				SELECT (cntr_value - @ReCompilationsPerSecond) / (
						CASE 
							WHEN DateDiff(ss, @StartDate, GetDate()) = 0 THEN 1 
							ELSE DateDiff(ss, @StartDate, GetDate()) 
						END) AS [SQLReCompilationsPerSecond], 1 X
					FROM #RatioStatsY
					WHERE counter_name = 'SQL Re-Compilations/sec'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:SQL Statistics' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':SQL Statistics' 
							END
			) L	ON A.X = L.X
			JOIN
			(
				SELECT *, 1 X 
					FROM #RatioStatsY
					WHERE counter_name = 'Target Server Memory (KB)'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Memory Manager' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Memory Manager' 
							END 
			) M	ON A.X = M.X
			JOIN
			(
				SELECT *, 1 X 
					FROM #RatioStatsY
					WHERE counter_name = 'Total Server Memory (KB)'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Memory Manager' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Memory Manager' 
							END
			) N ON A.X = N.X
			JOIN
			(
				SELECT 
						1 AS X,
						AVG(current_tasks_count)AS [AvgTaskCount],
						AVG(runnable_tasks_count)AS [AvgRunnableTaskCount],
						AVG(pending_disk_io_count) AS [AvgPendingDiskIOCount]
				FROM sys.dm_os_schedulers
					WHERE scheduler_id < 255
			) O ON A.X = O.X
			JOIN
			(
				SELECT 1 AS X, Sum(signal_wait_time_ms) / Sum (wait_time_ms) AS PercentSignalWait
					FROM sys.dm_os_wait_stats
			) P ON A.X = P.X
			JOIN
			(
				SELECT (cntr_value - @PageLookupsPerSecond) / (
						CASE 
							WHEN DateDiff(ss, @StartDate, GetDate()) = 0 THEN 1 
							ELSE DateDiff(ss, @StartDate, GetDate()) 
						END) AS [PageLookupsPerSecond], 1 X
					FROM #RatioStatsY
					WHERE counter_name = 'Page Lookups/sec'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Buffer Manager' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Buffer Manager' 
							END
			) Q ON A.X = Q.X
			JOIN
			(
				SELECT (cntr_value - @TransactionsPerSecond) / (
						CASE 
							WHEN DateDiff(ss, @StartDate, GetDate()) = 0 THEN 1 
							ELSE DateDiff(ss, @StartDate, GetDate()) 
						END) AS [TransactionsPerSecond], 1 X
				FROM #RatioStatsY
				WHERE counter_name = 'Transactions/sec' AND instance_name = '_Total'
					AND [object_name] = 
						CASE 
							WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Databases'
							ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Databases' 
						END
			) R	ON A.X = R.X
			JOIN
			(
				SELECT *, 1 X 
					FROM #RatioStatsY
					WHERE counter_name = 'Memory Grants Pending'
						AND [object_name] = 
							CASE 
								WHEN @@SERVICENAME = 'MSSQLSERVER' THEN 'SQLServer:Memory Manager' 
								ELSE 'MSSQL$' + RTrim(@@SERVICENAME) + ':Memory Manager' 
							END
			) S ON A.X = S.X


	IF(OBJECT_ID(N'tempdb..#RatioStatsX') IS NOT NULL)
		DROP TABLE #RatioStatsX

	IF(OBJECT_ID(N'tempdb..#RatioStatsY') IS NOT NULL)
		DROP TABLE #RatioStatsY

END