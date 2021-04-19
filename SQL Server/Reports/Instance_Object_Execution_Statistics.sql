USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--Object Execution Statistics
BEGIN TRY

	DECLARE @Cnt					INT
	DECLARE @RecordCount			INT
	DECLARE @DBID					INT
	DECLARE @ObjectID				INT
	DECLARE @Cmd					NVARCHAR(MAX)
	DECLARE @GrandTotalWorkerTime	FLOAT
	DECLARE @GrandTotalIO			FLOAT
	
	DECLARE @SQLHandleConvertTable TABLE
	(
		row_id					INT IDENTITY,
		--t_sql_handle			VARBINARY(64),
		--t_display_option		VARCHAR(140) COLLATE DATABASE_DEFAULT,
		--t_display_optionIO		VARCHAR(140) COLLATE DATABASE_DEFAULT,
		--t_sql_handle_text		VARCHAR(140) COLLATE DATABASE_DEFAULT,
		t_SPRank				INT,
		t_dbid					INT,
		t_objectid				INT,
		t_SQLStatement			VARCHAR(MAX) COLLATE DATABASE_DEFAULT,
		t_execution_count		INT,
		t_plan_generation_num	INT,
		t_last_execution_time	DATETIME,
		t_avg_worker_time		FLOAT,
		t_total_worker_time		FLOAT,
		t_last_worker_time		FLOAT,
		t_min_worker_time		FLOAT,
		t_max_worker_time		FLOAT,
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
		t_avg_logical_IO		FLOAT,
		t_total_logical_IO		BIGINT,
		t_last_logical_IO		BIGINT,
		t_min_logical_IO		BIGINT,
		t_max_logical_IO		BIGINT    
	)

	DECLARE @Objects TABLE 
	(
		obj_rank				INT,
		total_cpu				BIGINT,
		total_logical_reads		BIGINT,
		total_logical_writes	BIGINT,
		total_logical_io		BIGINT,
		avg_cpu					BIGINT,
		avg_reads				BIGINT,
		avg_writes				BIGINT,
		avg_io					BIGINT,
		cpu_rank				INT,
		total_cpu_rank			INT,
		logical_read_rank		INT,
		logical_write_rank		INT,
		logical_io_rank			INT
	)

	DECLARE @ObjectName TABLE 
	(
		[dbid]			INT,
		objectid		INT,
		dbName			SYSNAME COLLATE DATABASE_DEFAULT NULL,
		objectName		SYSNAME COLLATE DATABASE_DEFAULT NULL,
		objectType		NVARCHAR(5) COLLATE DATABASE_DEFAULT NULL,
		schemaName		SYSNAME COLLATE DATABASE_DEFAULT NULL
	)

	insert into @SQLHandleConvertTable 
		SELECT  
				--[sql_handle],
				--[sql_handle] AS chart_display_option ,
				--[sql_handle] AS chart_display_optionIO ,
				--master.dbo.fn_varbintohexstr([sql_handle]),
				DENSE_RANK() OVER (ORDER BY s2.[dbid], s2.objectid) AS SPRank,
				s2.[dbid],
				s2.objectid,
				(SELECT TOP 1 SubString([text], (s1.statement_start_offset + 2) / 2,(
						CASE
							WHEN s1.statement_End_offset = -1  THEN Len(Convert(NVARCHAR(MAX), [text])) * 2 
							ELSE s1.statement_End_offset 
						END - s1.statement_start_offset) /2) 
					FROM sys.dm_exec_sql_text(s1.[sql_handle])) AS [SQL Statement],
				execution_count,
				plan_generation_num,
				last_execution_time,
				Cast(((total_worker_time + 0.0) / execution_count) / 1000 AS DECIMAL(10,2)) AS [avg_worker_time],
				Cast(total_worker_time / 1000.0 AS DECIMAL(10,2)),
				Cast(last_worker_time / 1000.0 AS DECIMAL(10,2)),
				Cast(min_worker_time / 1000.0 AS DECIMAL(10,2)),
				Cast(max_worker_time / 1000.0 AS DECIMAL(10,2)),
				((total_logical_reads+0.0)/execution_count) AS [avg_logical_reads],
				total_logical_reads,
				last_logical_reads,
				min_logical_reads,
				max_logical_reads,
				Cast((total_logical_writes + 0.0) / execution_count AS DECIMAL(10,2)) AS [avg_logical_writes],
				total_logical_writes,
				last_logical_writes,
				min_logical_writes,
				max_logical_writes,
				Cast(((total_logical_writes + 0.0) / execution_count + (total_logical_reads + 0.0) / execution_count) AS DECIMAL(10,2)) AS [avg_logical_IO],
				total_logical_writes + total_logical_reads,
				last_logical_writes + last_logical_reads,
				min_logical_writes + min_logical_reads,
				max_logical_writes + max_logical_reads  
		FROM sys.dm_exec_query_stats s1 
			CROSS APPLY sys.dm_exec_sql_text([sql_handle]) AS  s2 
		WHERE s2.objectid IS NOT NULL AND DB_NAME(s2.[dbid]) IS NOT NULL
		ORDER BY s1.[sql_handle]; 

	SELECT @GrandTotalWorkerTime = Sum(t_total_worker_time) ,
			   @GrandTotalIO = Sum(t_total_logical_reads + t_total_logical_writes)  
	FROM @SQLHandleConvertTable; 

	SELECT @GrandTotalWorkerTime = CASE WHEN @GrandTotalWorkerTime > 0 THEN @GrandTotalWorkerTime ELSE 1.0 END
	SELECT @GrandTotalIO = CASE WHEN @GrandTotalIO > 0 THEN @GrandTotalIO ELSE 1.0 END

	Set @Cnt = 1;  
	SELECT @RecordCount = count(*) FROM @SQLHandleConvertTable  ; 
	
	While (@Cnt <= @RecordCount)  
	Begin  
		
		SELECT 
				@DBID = t_dbid,
				@ObjectID = t_objectid 
		FROM @SQLHandleConvertTable 
		WHERE row_id = @Cnt

		If(NOT EXISTS(SELECT 1 FROM @ObjectName WHERE objectid = @ObjectID AND [dbid] = @DBID))
		Begin

			Set @Cmd = 'SELECT ' + Convert(NVARCHAR(10), @DBID) + ',' + Convert(NVARCHAR(100), @ObjectID) + ',''' + DB_NAME(@DBID) + 
					   ''',obj.name,obj.type, CASE WHEN sch.name IS NULL THEN '''' ELSE sch.name END 
					   FROM [' + DB_NAME(@DBID) + '].sys.objects obj left outer join [' + DB_NAME(@DBID) + '].sys.schemas sch on(obj.schema_id = sch.schema_id) 
					   WHERE obj.object_id = ' + Convert(NVARCHAR(100),@ObjectID) + ';'

			INSERT INTO @ObjectName
				EXEC(@Cmd)
		End
		
		Set @Cnt = @Cnt + 1
	End

	INSERT INTO @Objects  
		SELECT 
			t_SPRank,
			Sum(t_total_worker_time),
			Sum(t_total_logical_reads),
			Sum(t_total_logical_writes),
			Sum(t_total_logical_IO),
			Sum(t_avg_worker_time) AS avg_cpu,
			Sum(t_avg_logical_reads),
			Sum(t_avg_logical_writes),
			Sum(t_avg_logical_IO),
			RANK() OVER(ORDER BY Sum(t_avg_worker_time) DESC),
			RANK() OVER(ORDER BY Sum(t_total_worker_time) DESC),
			RANK() OVER(ORDER BY Sum(t_avg_logical_reads) DESC),
			RANK() OVER(ORDER BY Sum(t_avg_logical_writes) DESC),
			RANK() OVER(ORDER BY Sum(t_total_logical_IO) DESC) 
		FROM @SQLHandleConvertTable 
		GROUP BY t_SPRank

	--UPDATE @SQLHandleConvertTable 
	--	SET t_display_option = 'show_total' 
	--	WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE (total_cpu + 0.0) / @GrandTotalWorkerTime < 0.05) 

	--UPDATE @SQLHandleConvertTable 
	--	SET t_display_option = t_sql_handle_text 
	--	WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE total_cpu_rank <= 5) ; 

	--UPDATE @SQLHandleConvertTable 
	--	SET t_display_option = 'show_total' 
	--	WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE (total_cpu + 0.0) / @GrandTotalWorkerTime < 0.005)

	--UPDATE @SQLHandleConvertTable 
	--	SET t_display_optionIO = 'show_total' 
	--	WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE (total_logical_io + 0.0) / @GrandTotalIO < 0.05)

	--UPDATE @SQLHandleConvertTable 
	--	SET t_display_optionIO = t_sql_handle_text 
	--	WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE logical_io_rank <= 5)

	--UPDATE @SQLHandleConvertTable 
	--	SET t_display_optionIO = 'show_total'  	
	--	WHERE t_SPRank IN (SELECT obj_rank FROM @Objects WHERE (total_logical_io + 0.0) / @GrandTotalIO < 0.005)
		 
	SELECT  
			(s.t_SPRank) % 2 AS l1,
			(DENSE_RANK() OVER(ORDER BY s.t_SPRank, s.row_id)) % 2 AS l2,
			s.*,
			ob.cpu_rank AS t_CPURank,
			ob.logical_read_rank AS t_logical_ReadRank,
			ob.logical_write_rank AS t_logical_WriteRank,
			objname.objectName AS t_obj_name,
			objname.objectType  AS [t_obj_type],
			objname.schemaName AS [schema_name],
			objname.dbName AS t_db_name
		FROM @SQLHandleConvertTable  s 
			JOIN @Objects ob ON (s.t_SPRank = ob.obj_rank)
			JOIN @ObjectName AS objname ON (objname.[dbid] = s.t_dbid AND objname.objectid = s.t_objectid )
END TRY 
BEGIN CATCH 
	SELECT 
		-100 AS l1,
		ERROR_NUMBER()  AS l2,
		ERROR_SEVERITY() AS row_id,
		ERROR_STATE() AS t_sql_handle,
		ERROR_MESSAGE() AS t_display_option,
		1 AS t_display_optionIO, 
		1 AS t_sql_handle_text, 
		1 AS t_SPRank,
		1 AS t_dbid,
		1 AS t_objectid,
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
		1 AS t_avg_logical_IO,
		1 AS t_total_logical_IO,
		1 AS t_last_logical_IO,
		1 AS t_min_logical_IO,
		1 AS t_max_logical_IO,
		1 AS t_CPURank,      
		1 AS t_logical_ReadRank,
		1 AS t_logical_WriteRank,
		1 AS t_obj_name, 
		1 AS t_obj_type, 
		1 AS schama_name,
		1 AS t_db_name 
END CATCH