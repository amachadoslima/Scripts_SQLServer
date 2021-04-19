USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

	DECLARE @TranTab TABLE
	(
		row_id	INT IDENTITY,
		tran_id BIGINT
	)

	INSERT INTO @TranTab 
		SELECT TOP 20 st.transaction_id 
			FROM sys.dm_tran_active_transactions [at]
				JOIN sys.dm_tran_session_transactions st ON ([at].transaction_id = st.transaction_id) 
			ORDER BY [at].transaction_begin_time

	SELECT 
			(tt.row_id) % 2 AS l1,
			(DENSE_RANK() OVER( ORDER BY tt.row_id, d.[name])) % 2 AS l2,
			st.transaction_id ,
			d.[name],
			dt.database_transaction_state AS database_tran_state,                  
			CASE 
				WHEN [sql_handle] IS NULL THEN '--' 
				ELSE (SELECT TOP 1 SubString([text], (statement_start_offset + 2) / 2, (
					CASE 
						WHEN statement_end_offset = -1 THEN (Len(Convert(NVARCHAR(MAX), [text])) * 2)
						ELSE statement_end_offset  
					END - statement_start_offset) / 2) FROM sys.dm_exec_sql_text([sql_handle])) 
			END AS [text],
			st.session_id,
			[at].[name] AS trans_name,
			[at].transaction_type AS trans_type,
			[at].transaction_begin_time AS tran_start_time,
			dt.database_transaction_begin_time AS first_update_time,
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
						ELSE 'Unknown' 
					END
				ELSE 
					CASE [at].dtc_isolation_level 
						WHEN 0xffffffff THEN 'Unknown' 
						WHEN 0x10 THEN 'Chaos' 
						WHEN 0x100 THEN 'Read Uncommitted' 
						WHEN 0x1000 THEN 'Read Committed' 
						WHEN 0x10000 THEN 'Repeatable Read' 
						WHEN 0x100000 THEN 'Serializable' 
						WHEN 0x1000000 THEN 'Isolated' 
					END
			END AS transaction_isolation_level,
			(SELECT COUNT(*) FROM sys.dm_tran_locks WHERE request_owner_id = st.transaction_id AND dt.database_id  = resource_database_id) AS tran_locks_count,
			(SELECT COUNT(DISTINCT database_id) FROM sys.dm_tran_database_transactions WHERE transaction_id = st.transaction_id) AS db_span_count,
			st.is_local,
			s.login_name
		FROM @TranTab tt 
			JOIN sys.dm_tran_active_transactions [at] ON (at.transaction_id = tt.tran_id) 
			LEFT OUTER JOIN sys.dm_tran_session_transactions st ON (st.transaction_id = tt.tran_id)
			LEFT OUTER JOIN  sys.dm_tran_database_transactions dt ON (st.transaction_id = dt.transaction_id) 
			LEFT OUTER JOIN sys.dm_exec_sessions s ON ( st.session_id = s.session_id) 
			LEFT OUTER JOIN sys.databases d ON (d.database_id = dt.database_id)
			LEFT OUTER JOIN sys.dm_exec_requests r ON (r.transaction_id = dt.transaction_id) 
		ORDER BY at.transaction_begin_time, d.[name]
END TRY
BEGIN CATCH
	SELECT
		-100 AS l1,
		1 AS l2,
		1 AS transaction_id,
		1 AS [name],
		1 AS database_tran_state,
		1 AS [text],
		1 AS session_id,
		1 AS trans_name,
		1 AS trans_type,
		1 AS tran_start_time,
		1 AS first_update_time,
		1 AS [state],
		1 AS tran_isolation_level,
		ERROR_NUMBER() AS tran_locks_count,
		ERROR_SEVERITY() AS db_span_count,
		ERROR_STATE() AS is_local,
		ERROR_MESSAGE() AS login_name
END CATCH