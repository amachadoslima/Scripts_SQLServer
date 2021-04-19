USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

	DECLARE @TabTranLocks AS TABLE
	(
		l_resource_type						NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		l_resource_subtype					NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		l_resource_associated_entity_id		BIGINT,
		l_blocking_request_spid				INT,
		l_blocked_request_spid				INT,
		l_blocking_request_mode				NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		l_blocked_request_mode				NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		l_blocking_tran_id					BIGINT,
		l_blocked_tran_id					BIGINT   
	)

	DECLARE @TabBlockedTran AS TABLE
	(
		tran_id		BIGINT,
		no_blocked	BIGINT
	)

	DECLARE @TempTab TABLE
	(
		blocking_status						INT,
		no_blocked							INT,
		l_resource_type						NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		l_resource_subtype					NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		l_resource_associated_entity_id		BIGINT,
		l_blocking_request_spid				INT,
		l_blocked_request_spid				INT,
		l_blocking_request_mode				NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		l_blocked_request_mode				NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		l_blocking_tran_id					INT,
		l_blocked_tran_id					INT, 
		local1								INT,
		local2								INT,
		b_tran_id							BIGINT,
		w_tran_id							BIGINT,
		b_name								NVARCHAR(128) COLLATE DATABASE_DEFAULT,
		w_name								NVARCHAR(128) COLLATE DATABASE_DEFAULT,
		b_tran_begin_time					DATETIME,
		w_tran_begin_time					DATETIME,
		b_state								NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		w_state								NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		b_trans_type						NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		w_trans_type						NVARCHAR(60) COLLATE DATABASE_DEFAULT,
		b_text								NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
		w_text								NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
		db_span_count1						INT,
		db_span_count2						INT 
	)

	INSERT INTO @TabTranLocks 
		SELECT  
				a.resource_type,
				a.resource_subtype,
				a.resource_associated_entity_id,
				a.request_session_id AS blocking,
				b.request_session_id AS blocked,
				a.request_mode,
				b.request_mode,
				a.request_owner_id,
				b.request_owner_id  
			FROM sys.dm_tran_locks a 
				JOIN sys.dm_tran_locks b ON (a.resource_type = b.resource_type AND a.resource_subtype = b.resource_subtype AND 
										     a.resource_associated_entity_id = b.resource_associated_entity_id AND a.resource_description = b.resource_description)
			WHERE a.request_status = 'GRANT' AND (b.request_status = 'WAIT' OR b.request_status = 'CONVERT') AND a.request_owner_type = 'TRANSACTION' AND b.request_owner_type = 'TRANSACTION'

	INSERT INTO @TabBlockedTran 
		SELECT ttl.l_blocking_tran_id, COUNT(DISTINCT ttl.l_blocked_tran_id)
			FROM @TabTranLocks ttl   
			GROUP BY ttl.l_blocking_tran_id
			ORDER BY COUNT(DISTINCT ttl.l_blocked_tran_id) DESC 

	INSERT INTO @TempTab 
		SELECT  
				0 AS blocking_status,
				tbt.no_blocked,
				ttl.*,
				st1.is_local AS local1,
				st2.is_local AS local2,
				st1.transaction_id AS b_tran_id,
				ttl.l_blocked_tran_id AS w_tran_id,
				at1.[name] AS b_name,at2.[name] AS w_name,
				at1.transaction_begin_time AS b_tran_begin_time,
				at2.transaction_begin_time AS w_tran_begin_time,
				CASE 
					WHEN at1.transaction_type <> 4 THEN 
						CASE at1.transaction_state 
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
					CASE at1.dtc_state 
						WHEN 1 THEN 'Active' 
						WHEN 2 THEN 'Prepared' 
						WHEN 3 THEN 'Committed' 
						WHEN 4 THEN 'Aborted' 
						WHEN 5 THEN 'Recovered' 
					END
				END b_state,
				CASE 
					WHEN at2.transaction_type <> 4 THEN 
						CASE at2.transaction_state 
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
						CASE at2.dtc_state 
							WHEN 1 THEN 'Active' 
							WHEN 2 THEN 'Prepared' 
							WHEN 3 THEN 'Committed' 
							WHEN 4 THEN 'Aborted' 
							WHEN 5 THEN 'Recovered' 
						END
				END w_state,
				at1.transaction_type AS b_trans_type,
				at2.transaction_type  AS w_trans_type,
				CASE
					WHEN r1.[sql_handle] IS NULL THEN '--' 
					ELSE (SELECT TOP 1 SubString([text], (r1.statement_start_offset + 2) / 2, (
						CASE 
							WHEN r1.statement_end_offset = -1 THEN (Len(Convert(NVARCHAR(MAX), [text])) * 2) 
							ELSE r1.statement_end_offset  
						END - r1.statement_start_offset) / 2) FROM sys.dm_exec_sql_text(r1.[sql_handle])) 
				END AS b_text,
				CASE 
					WHEN r2.[sql_handle] IS NULL THEN '--' 
					ELSE (SELECT TOP 1 Substring([text], (r2.statement_start_offset + 2) / 2, (
						CASE 
							WHEN r2.statement_end_offset = -1 THEN Len(Convert(NVARCHAR(MAX), [text])) * 2  
							WHEN r2.statement_end_offset = 0  THEN Len(Convert(NVARCHAR(MAX), [text])) * 2  
							ELSE r2.statement_end_offset  
						END - r2.statement_start_offset) / 2) FROM sys.dm_exec_sql_text(r2.[sql_handle])) 
				END AS w_text,
				(SELECT COUNT(DISTINCT database_id) FROM sys.dm_tran_database_transactions WHERE transaction_id = st1.transaction_id) AS db_span_count1,
				(SELECT COUNT(DISTINCT database_id) FROM sys.dm_tran_database_transactions WHERE transaction_id = st2.transaction_id) AS db_span_count2  
			FROM @TabTranLocks ttl 
				JOIN sys.dm_tran_active_transactions at1 ON (at1.transaction_id = ttl.l_blocking_tran_id) 
				JOIN @TabBlockedTran tbt ON (tbt.tran_id = at1.transaction_id)  
				JOIN sys.dm_tran_session_transactions st1 ON (at1.transaction_id = st1.transaction_id) 
				LEFT OUTER JOIN sys.dm_exec_requests r1 ON (at1.transaction_id = r1.transaction_id ) 
				JOIN sys.dm_tran_active_transactions at2 ON (at2.transaction_id = ttl.l_blocked_tran_id) 
				LEFT OUTER JOIN sys.dm_tran_session_transactions st2 ON (at2.transaction_id = st2.transaction_id)  
				LEFT OUTER JOIN  sys.dm_exec_requests r2 ON (at2.transaction_id = r2.transaction_id ) 
			WHERE st1.is_user_transaction = 1
			ORDER BY tbt.no_blocked DESC

	;WITH Blocking
	(
		blocking_status,
		no_blocked,
		total_blocked,
		l_resource_type,
		l_resource_subtype,
		l_resource_associated_entity_id,
		l_blocking_request_spid,
		l_blocked_request_spid,
		l_blocking_request_mode,
		l_blocked_request_mode,
		local1,
		local2,
		b_tran_id,
		w_tran_id,
		b_name,
		w_name,
		b_tran_begin_time,
		w_tran_begin_time,
		b_state,
		w_state,
		b_trans_type,
		w_trans_type,
		b_text,
		w_text,
		db_span_count1,
		db_span_count2,
		lvl
	)
	AS
	( 
			SELECT 
					blocking_status,
					no_blocked,
					no_blocked,
					l_resource_type,
					l_resource_subtype,
					l_resource_associated_entity_id,
					l_blocking_request_spid,
					l_blocked_request_spid,
					l_blocking_request_mode,
					l_blocked_request_mode,
					local1,
					local2,
					b_tran_id,
					w_tran_id,
					b_name,
					w_name,
					b_tran_begin_time,
					w_tran_begin_time,
					b_state,
					w_state,
					b_trans_type,
					w_trans_type,
					b_text,
					w_text,
					db_span_count1,
					db_span_count2,
					0
				FROM @TempTab
		UNION ALL
			SELECT 
					E.blocking_status,
					M.no_blocked,
					Convert(INT, E.no_blocked + total_blocked),
					E.l_resource_type,
					E.l_resource_subtype,
					E.l_resource_associated_entity_id,
					M.l_blocking_request_spid,
					E.l_blocked_request_spid,
					M.l_blocking_request_mode,
					E.l_blocked_request_mode,
					M.local1,
					E.local2,
					M.b_tran_id,
					E.w_tran_id,
					M.b_name,
					E.w_name,
					M.b_tran_begin_time,
					E.w_tran_begin_time,
					M.b_state,
					E.w_state,
					M.b_trans_type,
					E.w_trans_type,
					M.b_text,
					E.w_text,
					M.db_span_count1,
					E.db_span_count2,
					M.lvl + 1
				FROM @TempTab AS E
					JOIN Blocking AS M ON E.b_tran_id = M.w_tran_id
	)
	SELECT 
			(DENSE_RANK() OVER (ORDER BY no_blocked DESC, b_tran_id)) % 2 AS l1,
			(DENSE_RANK() OVER (ORDER BY no_blocked DESC, b_tran_id,w_tran_id)) % 2 AS l2,
			*
		FROM Blocking 
			ORDER BY no_blocked DESC, b_tran_id,w_tran_id
END TRY
BEGIN CATCH

	SELECT
		-100 AS l1,
		ERROR_NUMBER() AS l2,
		ERROR_SEVERITY() AS blocking_status,
		ERROR_STATE() AS no_blocked,
		ERROR_MESSAGE() AS total_blocked,
		1 AS l_resource_type,
		1 AS l_resource_subtype,
		1 AS l_resource_associated_entity_id,
		1 AS l_blocking_request_spid,
		1 AS l_blocked_request_spid,
		1 AS l_blocking_request_mode,
		1 AS l_blocked_request_mode,
		1 AS local1,
		1 AS local2,
		1 AS b_tran_id,
		1 AS w_tran_id,
		1 AS b_name,
		1 AS w_name,
		1 AS b_tran_begin_time,
		1 AS w_tran_begin_time,
		1 AS b_state,
		1 AS w_state,
		1 AS b_trans_type,
		1 AS w_trans_type,
		1 AS b_text,
		1 AS w_text,
		1 AS db_span_count1,
		1 AS db_span_count2,
		1 AS lvl
END CATCH