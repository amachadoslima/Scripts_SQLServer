USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

	DECLARE @DBID				INT
	DECLARE @DBName				SYSNAME
	DECLARE @ResourceType		NVARCHAR(60)
	DECLARE @ObjOrHobtID		BIGINT
	DECLARE @Cnt				INT
	DECLARE @ObjCnt				INT
	DECLARE @Cmd				NVARCHAR(MAX)

	DECLARE @TopPran TABLE
	(
		tran_id							BIGINT,
		[sql_handle]					VARBINARY(68),
		statement_start_offset			INT,
		statement_end_offset			INT,
		tran_name						SYSNAME COLLATE DATABASE_DEFAULT NULL,
		session_id						INT,
		tran_type						INT,
		tran_start_time					DATETIME,
		tran_state						NVARCHAR(50) COLLATE DATABASE_DEFAULT,
		transaction_isolation_level		NVARCHAR(50) COLLATE DATABASE_DEFAULT, 
		db_span_count					INT,
		is_local						TINYINT,
		locks_count						AS (metadata_locks_count + database_locks_count + file_locks_count + table_locks_count+extent_locks_count +
																   page_locks_count + row_locks_count + others_locks_count),
		metadata_locks_count			INT,
		database_locks_count			INT,
		file_locks_count				INT,
		table_locks_count				INT,
		extent_locks_count				INT,
		page_locks_count				INT,
		row_locks_count					INT,
		others_locks_count				INT,
		login_name						SYSNAME  COLLATE DATABASE_DEFAULT NULL
	)

	DECLARE @DBTran TABLE
	(
		tran_id						BIGINT,
		[db_name]					SYSNAME COLLATE DATABASE_DEFAULT NULL,
		[db_id]						INT,
		db_tran_state				NVARCHAR(50) COLLATE DATABASE_DEFAULT,
		db_tran_begin_time			DATETIME,
		db_locks_count				AS(db_metadata_locks_count + db_database_locks_count + db_file_locks_count + db_table_locks_count + 
																 db_extent_locks_count + db_page_locks_count + db_row_locks_count + db_others_locks_count),
		db_metadata_locks_count		INT,
		db_database_locks_count		INT,
		db_file_locks_count			INT,
		db_table_locks_count		INT,
		db_extent_locks_count		INT,
		db_page_locks_count			INT,
		db_row_locks_count			INT,
		db_others_locks_count		INT
	)

	DECLARE @TranLocks TABLE 
	(
		row_no						INT IDENTITY,
		tran_id						BIGINT,
		obj_or_hobt_id				BIGINT,
		[db_id]						INT,
		resource_type				NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		resource_rank				SMALLINT,
		request_status				NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		request_mode				NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		[count]						BIGINT
	)

	DECLARE @ObjInfo TABLE 
	(
		[db_id]						INT,
		obj_or_hobt_id				BIGINT,
		obj_id						BIGINT,
		obj_name					SYSNAME COLLATE DATABASE_DEFAULT NULL,
		[schema_name]				SYSNAME COLLATE DATABASE_DEFAULT NULL
	)

	insert into @TopPran
		SELECT TOP 20 
				st.transaction_id,
				r.[sql_handle],
				r.statement_start_offset,
				r.statement_end_offset,
				[at].[name] AS trans_name,
				st.session_id,
				[at].transaction_type AS trans_type,
				[at].transaction_begin_time AS tran_start_time,
				CASE 
					WHEN [at].transaction_type <> 4 THEN 
						CASE [at].transaction_state 
							WHEN 0 THEN 'Invalid' 
							WHEN 1 THEN 'Initialized' 
							WHEN 2 THEN 'Active' 
							WHEN 3 THEN 'Ended' 
							WHEN 4 THEN 'Commit Started' 
							WHEN 5 THEN 'Prepared' 
							WHEN 6 THEN 'Committed' 
							WHEN 7 THEN 'Rolling Back' 
							WHEN 8 THEN 'Rolled Back' 
						END
					ELSE 
						CASE [at].dtc_state 
							WHEN 1 THEN 'Active' 
							WHEN 2 THEN 'Prepared' 
							WHEN 3 THEN 'Committed' 
							WHEN 4 THEN 'Aborted' 
							WHEN 5 THEN 'Recovered' 
						END 
				END [state],
				CASE 
					WHEN [at].transaction_type <> 4 THEN 
						CASE Convert(INT, r.transaction_isolation_level) 
							WHEN 1 THEN 'Read Uncommitted' 
							WHEN 2 THEN 'Read Committed' 
							WHEN 3 THEN 'Repeatable Read' 
							WHEN 4 THEN 'Serializable' 
							WHEN 5 THEN 'Snapshot' 
							ELSE 'Unspecified' 
						END  
					ELSE 
						CASE [at].dtc_isolation_level 
							WHEN 0xffffffff THEN 'Unspecified' 
							WHEN 0x10 THEN 'Chaos' 
							WHEN 0x100 THEN 'Read Uncommitted' 
							WHEN 0x1000 THEN 'Read Committed' 
							WHEN 0x10000 THEN 'Repeatable Read' 
							WHEN 0x100000 THEN 'Serializable' 
							WHEN 0x100000 THEN 'Isolated' 
						END 
				END AS tran_isolation_level,
				(SELECT COUNT(DISTINCT database_id) FROM sys.dm_tran_database_transactions WHERE transaction_id = st.transaction_id) AS db_span_count,
				st.is_local,
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = st.transaction_id AND resource_type = 'METADATA') AS 'Metadata Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = st.transaction_id AND resource_type = 'DATABASE') AS 'Database Locks Count', 
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = st.transaction_id AND resource_type = 'FILE') AS 'File Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = st.transaction_id AND resource_type = 'TABLE') AS 'Table Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = st.transaction_id AND resource_type = 'EXTENT') AS 'Extent Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = st.transaction_id AND resource_type = 'PAGE') AS 'Page Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = st.transaction_id AND resource_type IN ('RID','KEY','HOBT')) AS 'Row Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = st.transaction_id AND resource_type NOT IN ('METADATA','DATABASE','FILE','TABLE','EXTENT','PAGE','RID','KEY','HOBT')) AS 'Other Locks Count',
				s.login_name   
			FROM sys.dm_tran_active_transactions [at]
				JOIN sys.dm_tran_session_transactions st ON ([at].transaction_id = st.transaction_id) 
				LEFT OUTER JOIN sys.dm_exec_sessions s ON (st.session_id = s.session_id) 
				LEFT OUTER JOIN sys.dm_exec_requests r ON (r.transaction_id = st.transaction_id) 
			WHERE (st.is_user_transaction = 1) 
			ORDER BY [Metadata Locks Count] DESC,
					 [Database Locks Count] DESC,
					 [File Locks Count] DESC,
					 [Table Locks Count] DESC,
					 [Extent Locks Count] DESC,
					 [Page Locks Count] DESC,
					 [Row Locks Count] DESC,
					 [Other Locks Count] DESC

	INSERT INTO @DBTran
		SELECT 
				dt.transaction_id,
				DB_NAME(dt.database_id),
				dt.database_id,
				CASE dt.database_transaction_state 
					WHEN 1 THEN 'Uninitialized'
					WHEN 3 THEN 'Initialized'
					WHEN 4 THEN 'Active'
					WHEN 5 THEN 'Prepared'
					WHEN 10 THEN 'Committed'
					WHEN 11 THEN 'Rolled Back'
					WHEN 12 THEN 'Commiting'
					ELSE  'Unknown State' 
				END AS db_tran_state,
				dt.database_transaction_begin_time, 
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = dt.transaction_id AND dt.database_id  = resource_database_id AND resource_type = 'METADATA') AS 'Metadata Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = dt.transaction_id AND dt.database_id  = resource_database_id AND resource_type = 'DATABASE') AS 'Database Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = dt.transaction_id AND dt.database_id  = resource_database_id AND resource_type = 'FILE') AS 'File Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = dt.transaction_id AND dt.database_id  = resource_database_id AND resource_type = 'TABLE') AS 'Table Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = dt.transaction_id AND dt.database_id  = resource_database_id AND resource_type = 'EXTENT') AS 'Extent Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = dt.transaction_id AND dt.database_id  = resource_database_id AND resource_type = 'PAGE') AS 'Page Locks Count',
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = dt.transaction_id AND dt.database_id  = resource_database_id AND resource_type IN ('RID','KEY','HOBT')) AS 'Row Locks Count', 
				(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = dt.transaction_id AND dt.database_id  = resource_database_id AND resource_type NOT IN ('METADATA','DATABASE','FILE','TABLE','EXTENT','PAGE','RID','KEY','HOBT')) AS 'Other Locks Count'
			FROM sys.dm_tran_database_transactions dt 
			WHERE dt.transaction_id IN (SELECT tran_id FROM @TopPran)
        
	INSERT INTO @TranLocks
		SELECT 
				request_owner_id,
				resource_associated_entity_id,
				resource_database_id,
				resource_type,
				CASE resource_type 
					WHEN 'METADATA'  THEN 1 
					WHEN 'DATABASE' THEN 2 
					WHEN 'FILE' THEN 3 
					WHEN 'TABLE' THEN 4 
					WHEN 'HOBT' THEN 5 
					WHEN 'EXTENT' THEN 6 
					WHEN 'PAGE' THEN 7 
					WHEN 'KEY' THEN 8 
					WHEN 'RID' THEN 9 
					WHEN 'ALLOCATION_UNIT' THEN 10 
					WHEN 'APPLICATION' THEN 11 
				END,
				request_status,
				Convert(VARCHAR, request_mode) AS request_mode,
				COUNT(*)
			FROM sys.dm_tran_locks 
			WHERE request_owner_id IN (SELECT tran_id FROM @TopPran)
			GROUP BY request_owner_id, resource_associated_entity_id, request_status, resource_type, resource_database_id, request_mode


	SELECT @Cnt = COUNT(*) FROM @TranLocks

	While(@Cnt > 0)
	Begin

		SELECT 
				@DBID = [db_id],
				@ObjOrHobtID = obj_or_hobt_id,
				@ResourceType = resource_type
			FROM @TranLocks 
			WHERE row_no = @Cnt
        
		Set @DBName = DB_NAME(@DBID)
		SELECT @ObjCnt = COUNT(*) 
			FROM @ObjInfo 
			WHERE [db_id] = @DBID 
				AND obj_or_hobt_id = @ObjOrHobtID
        
		If (@ObjCnt = 0)
		Begin

			If(@ResourceType IN ('PAGE','RID'))
				Set @Cmd = 'SELECT ' + Convert(NVARCHAR(10), @DBID) + ',' + Convert(NVARCHAR(50), @ObjOrHobtID)+
						   ',o.object_id,o.name,s.name FROM [' + @DBName + '].sys.partitions p JOIN [' + @DBName + '].sys.objects o '+
						   'ON (p.object_id = o.object_id) JOIN [' + @DBName + '].sys.schemas s ON (o.schema_id = s.schema_id) '+
						   'WHERE p.hobt_id = ' + Convert(NVARCHAR(50), @ObjOrHobtID)
			Else 
				Set @Cmd = 'SELECT ' + Convert(NVARCHAR(10), @DBID) + ',' + Convert(NVARCHAR(50), @ObjOrHobtID)+
						   ',o.object_id,o.name,s.name from [' + @DBName + '].sys.objects o JOIN [' + @DBName +
						   '].sys.schemas s ON (o.schema_id = s.schema_id) '+
						   'WHERE o.object_id = ' + Convert(NVARCHAR(50), @ObjOrHobtID)
        
			INSERT INTO @ObjInfo
				EXEC(@Cmd)
		End

		Set @Cnt = @Cnt - 1

	End

	SELECT  
			(DENSE_RANK() OVER (ORDER BY tt.metadata_locks_count DESC,
										 tt.database_locks_count DESC,
										 tt.file_locks_count DESC,
										 tt.table_locks_count DESC,
										 tt.extent_locks_count DESC,
										 tt.page_locks_count DESC,
										 tt.row_locks_count DESC,
										 tt.others_locks_count DESC,
										 tt.tran_id)) % 2 AS l1,
			(DENSE_RANK() OVER (ORDER BY tt.metadata_locks_count DESC,
										 tt.database_locks_count DESC,
										 tt.file_locks_count DESC,
										 tt.table_locks_count DESC,
										 tt.extent_locks_count DESC,
										 tt.page_locks_count DESC,
										 tt.row_locks_count DESC,
										 tt.others_locks_count DESC,
										 tt.tran_id,
										 dt.[db_name])) % 2 AS l2,
			(DENSE_RANK() OVER (ORDER BY tt.metadata_locks_count DESC,
										 tt.database_locks_count DESC,
										 tt.file_locks_count DESC,
										 tt.table_locks_count DESC,
										 tt.extent_locks_count DESC,
										 tt.page_locks_count DESC,
										 tt.row_locks_count DESC,
										 tt.others_locks_count DESC,
										 tt.tran_id,
										 dt.[db_name],
										 oi.[schema_name],
										 oi.obj_name)) % 2 AS l3,
	       (DENSE_RANK() OVER (ORDER BY  tt.metadata_locks_count DESC,
										 tt.database_locks_count DESC,
										 tt.file_locks_count DESC,   
										 tt.table_locks_count DESC,
										 tt.extent_locks_count DESC,
										 tt.page_locks_count DESC,
										 tt.row_locks_count DESC,
										 tt.others_locks_count DESC,
										 tt.tran_id,
										 dt.[db_name],
										 oi.[schema_name],
										 oi.obj_name,
										 tl.resource_rank
										 )) % 2 AS l4,
			*,
			CASE 
				WHEN [sql_handle] IS NULL THEN '--' 
				ELSE (SELECT TOP 1 SubString([text], statement_start_offset / 2, (
					CASE 
						WHEN statement_end_offset = -1  THEN Len(Convert(NVARCHAR(MAX), [text])) * 2 
						ELSE statement_end_offset  
					END - statement_start_offset) / 2) FROM sys.dm_exec_sql_text([sql_handle])) 
			END AS [text]
		FROM @TopPran tt
			JOIN @DBTran dt ON (tt.tran_id = dt.tran_id)
			JOIN @TranLocks tl ON (tt.tran_id = tl.tran_id and dt.[db_id] = tl.[db_id])
			JOIN @ObjInfo oi ON (tl.[db_id] = oi.[db_id] and tl.obj_or_hobt_id = oi.obj_or_hobt_id)
END TRY
BEGIN CATCH
	SELECT 
		-100 AS l1,
		1 AS l2,
		1 AS l3,
		1 AS l4,
		1 AS tran_id,
		1 AS [sql_handle],
		1 AS statement_start_offset,
		1 AS statement_end_offset,
		1 AS tran_name,
		1 AS session_id,1 AS tran_type,
		1 AS tran_start_time,
		1 AS tran_state,
		1 AS tran_isolation_level,
		1 AS db_span_count,
		1 AS is_local,
		1 AS locks_count,
		1 AS metadata_locks_count,
		1 AS database_locks_count,
		1 AS file_locks_count,
		1 AS table_locks_count,
		1 AS extent_locks_count,
		1 AS page_locks_count,
		1 AS row_locks_count,
		1 AS others_locks_count,
		1 AS login_name,
		1 AS tran_id_1,
		1 AS DB_NAME,1 AS [db_id],
		1 AS db_tran_begin_time,
		1 AS db_locks_count,
		1 AS db_metadata_locks_count,
		1 AS db_database_locks_count,
		1 AS db_file_locks_count,
		1 AS db_table_locks_count,
		1 AS db_extent_locks_count,
		1 AS db_page_locks_count,
		1 AS db_row_locks_count,
		1 AS db_others_locks_count,
		1 AS row_no,
		1 AS tran_id_2,
		1 AS obj_or_hobt_id,
		1 AS db_id_1,
		1 AS resource_type,
		1 AS resource_rank,
		1 AS request_status,
		1 AS request_mode,
		1 AS [count],
		1 AS db_id_2,
		1 AS obj_or_hobt_id_1,
		ERROR_NUMBER()  AS obj_id,
		ERROR_SEVERITY() AS obj_name,
		ERROR_STATE() AS [schema_name],
		ERROR_MESSAGE() AS text
END CATCH