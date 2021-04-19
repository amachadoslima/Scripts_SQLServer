USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY 

	DECLARE @DBID INT
	Set @DBID = DB_ID()

	DECLARE @Top						INT
	DECLARE @Cnt						INT
	DECLARE @RecordCount				INT
	DECLARE @SqlHandle					VARBINARY(64) 
	DECLARE @SqlHandleString			VARCHAR(130)
	DECLARE @GrantTotalWorkerTime		FLOAT
	DECLARE @GrandTotalIO				FLOAT

	Set @Top = 500

	DECLARE @SqlHandleConvertTable TABLE
	(
		row_id					INT IDENTITY,
		--t_sql_handle			VARBINARY(64),
		--t_display_option		VARCHAR(140) COLLATE DATABASE_DEFAULT,
		--t_display_optionIO		VARCHAR(140) COLLATE DATABASE_DEFAULT,
		--t_sql_handle_text		VARCHAR(140) COLLATE DATABASE_DEFAULT,
		t_SPRank				INT,
		t_SPRank2				INT,
		t_SQLStatement			VARCHAR(MAX) COLLATE DATABASE_DEFAULT,
		t_execution_count		INT,
		t_plan_generation_num	INT,
		t_last_execution_time	DATETIME,
		t_avg_worker_time		FLOAT,
		t_total_worker_time		BIGINT,
		t_last_worker_time		BIGINT,
		t_min_worker_time		BIGINT,
		t_max_worker_time		BIGINT ,
		t_avg_logical_reads		FLOAT,
		t_total_logical_reads	BIGINT,
		t_last_logical_reads	BIGINT,
		t_min_logical_reads		BIGINT,
		t_max_logical_reads		BIGINT,
		t_avg_logical_writes	FLOAT,
		t_total_logical_writes	BIGINT,
		t_last_logical_writes	BIGINT,
		t_min_logical_writes	BIGINT,
		t_max_logical_writes	BIGINT,
		t_avg_IO				FLOAT,
		t_total_IO				BIGINT,
		t_last_IO				BIGINT,
		t_min_IO				BIGINT,
		t_max_IO				BIGINT
	)

	DECLARE @Objects TABLE 
	(
		obj_rank				INT,
		total_cpu				BIGINT, 
		total_reads				BIGINT,
		total_writes			BIGINT,
		otal_io					BIGINT,
		avg_cpu					BIGINT ,
		avg_reads				BIGINT,
		avg_writes				BIGINT,
		avg_io					BIGINT,
		cpu_rank				INT,
		total_cpu_rank			INT,
		read_rank				INT,
		write_rank				INT,
		io_rank					INT
	)

	INSERT INTO @SqlHandleConvertTable 
		SELECT TOP (@Top)
				--[sql_handle],
				--[sql_handle] AS chart_display_option,
				--[sql_handle] AS chart_display_optionIO,
				--master.dbo.fn_varbintohexstr([sql_handle]),
				DENSE_RANK() OVER (ORDER BY s1.[sql_handle]) AS SPRank,
				DENSE_RANK() OVER (PARTITION BY s1.[sql_handle] ORDER BY s1.statement_start_offset) AS SPRank2,
				(SELECT TOP 1 SubString([text], (s1.statement_start_offset + 2) / 2, (
					CASE 
						WHEN s1.statement_end_offset = -1 THEN Len(Convert(NVARCHAR(MAX), [text])) * 2 
						ELSE s1.statement_end_offset 
					END - s1.statement_start_offset) / 2) FROM sys.dm_exec_sql_text(s1.[sql_handle])) AS [SQL Statement],
				execution_count,
				plan_generation_num,
				last_execution_time,
				Cast(((total_worker_time + 0.0) / execution_count) / 1000 AS DECIMAL(10,2)) AS [avg_worker_time],
				Cast(total_worker_time / 1000 AS DECIMAL(10,2)),
				Cast(last_worker_time / 1000 AS DECIMAL(10,2)),
				Cast(min_worker_time / 1000 AS DECIMAL(10,2)),
				Cast(max_worker_time / 1000 AS DECIMAL(10,2)),
				Cast(((total_logical_reads + 0.0) / execution_count)  AS DECIMAL(10,2)) AS [avg_logical_reads],
				total_logical_reads,
				last_logical_reads,
				min_logical_reads,
				max_logical_reads,
				Cast(((total_logical_writes + 0.0) / execution_count)  AS DECIMAL(10,2)) AS [avg_logical_writes],
				total_logical_writes,
				last_logical_writes,
				min_logical_writes,
				max_logical_writes,
				Cast((total_logical_writes + 0.0) / execution_count + (total_logical_reads + 0.0) / execution_count AS DECIMAL(10,2)) AS [avg_IO],
				total_logical_writes + total_logical_reads,
				last_logical_writes + last_logical_reads,
				min_logical_writes + min_logical_reads,
				max_logical_writes + max_logical_reads  
			FROM sys.dm_exec_query_stats s1 
				CROSS APPLY sys.dm_exec_sql_text([sql_handle]) AS  s2 
			WHERE s2.objectid IS NULL
			--ORDER BY  s1.[sql_handle] -- Ordenação padrão (original)
			ORDER BY s1.last_execution_time DESC

	SELECT @GrantTotalWorkerTime = Sum(t_total_worker_time), @GrandTotalIO = Sum(t_total_logical_reads + t_total_logical_writes)  
		FROM @SqlHandleConvertTable

	SELECT @GrantTotalWorkerTime = CASE WHEN @GrantTotalWorkerTime > 0 THEN @GrantTotalWorkerTime ELSE 1.0 END
	SELECT @GrandTotalIO = CASE WHEN @GrandTotalIO > 0 THEN @GrandTotalIO ELSE 1.0 END

	INSERT INTO @Objects  
		SELECT 
				t_SPRank,
				Sum(t_total_worker_time),
				Sum(t_total_logical_reads),
				Sum(t_total_logical_writes),
				Sum(t_total_IO),
				Sum(t_avg_worker_time) AS avg_cpu,
				Sum(t_avg_logical_reads),
				Sum(t_avg_logical_writes),
				Sum(t_avg_IO),
				RANK() OVER(ORDER BY Sum(t_avg_worker_time) DESC),
				ROW_NUMBER() OVER(ORDER BY Sum(t_total_worker_time) DESC),
				ROW_NUMBER() OVER(ORDER BY Sum(t_avg_logical_reads) DESC),
				ROW_NUMBER() OVER(ORDER BY Sum(t_avg_logical_writes) DESC),
				ROW_NUMBER() OVER(ORDER BY Sum(t_total_IO) DESC) 
			FROM @SqlHandleConvertTable 
			GROUP BY t_SPRank

	/*
	UPDATE @SqlHandleConvertTable 
		SET t_display_option = 'show_total' 
		WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE (total_cpu + 0.0) / @GrantTotalWorkerTime < 0.05)

	UPDATE @SqlHandleConvertTable 
		SET t_display_option = t_sql_handle_text 
		WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE total_cpu_rank <= 5) 

	UPDATE @SqlHandleConvertTable 
		SET t_display_option = 'show_total' 
		WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE (total_cpu + 0.0) / @GrantTotalWorkerTime < 0.005)

	UPDATE @SqlHandleConvertTable 
		SET t_display_optionIO = 'show_total' 
		WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE (total_io + 0.0) / @GrandTotalIO < 0.05)

	UPDATE @SqlHandleConvertTable 
		SET t_display_optionIO = t_sql_handle_text 
		WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE io_rank <= 5)

	UPDATE @SqlHandleConvertTable 
		SET t_display_optionIO = 'show_total'  
		WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE (total_io + 0.0) / @GrandTotalIO < 0.005)
	*/

	SELECT 
			(s.t_SPRank) % 2 AS l1,
			(DENSE_RANK() OVER(ORDER BY s.t_SPRank, s.row_id)) % 2 AS l2,
			s.*,
			ob.cpu_rank AS t_CPURank,
			ob.read_rank AS t_ReadRank,
			ob.write_rank AS t_WriteRank
		FROM @SqlHandleConvertTable  s 
			JOIN @Objects ob ON (s.t_SPRank = ob.obj_rank)
END TRY
BEGIN CATCH
	SELECT 
		-100 AS l1,
		ERROR_NUMBER() AS l2,
		ERROR_SEVERITY() AS row_id,
		ERROR_STATE() AS t_sql_handle,
		ERROR_MESSAGE() AS t_display_option,
		1 AS t_display_optionIO
		,1 AS t_sql_handle_text,
		1 AS t_SPRank,
		1 AS t_SPRank2,
		1 AS t_SQLStatement,
		1 AS t_execution_count,
		1 AS t_plan_generation_num,
		1 AS t_last_execution_time,            
		1 AS t_avg_worker_time,        
		1 AS t_total_worker_time,
		1 AS t_last_worker_time,
		1 AS t_min_worker_time,
		1 AS t_max_worker_time,
		1 AS t_avg_logical_reads,
		1 AS t_total_logical_reads,
		1 AS t_last_logical_reads,
		1 AS t_min_logical_reads,
		1 AS t_max_logical_reads,
		1 AS t_avg_logical_writes,
		1 AS t_total_logical_writes,
		1 AS t_last_logical_writes,
		1 AS t_min_logical_writes,
		1 AS t_max_logical_writes,
		1 AS t_avg_IO,
		1 AS t_total_IO ,
		1 AS t_last_IO,
		1 AS t_min_IO,
		1 AS t_max_IO,
		1 AS t_CPURank,
		1 AS t_ReadRank,
		1 AS t_WriteRank
END CATCH