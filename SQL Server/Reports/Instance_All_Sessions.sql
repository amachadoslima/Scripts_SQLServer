USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

	SELECT
			--(DENSE_RANK() OVER (ORDER BY s.login_name)) % 2 AS l1,
			--(DENSE_RANK() OVER (PARTITION BY s.login_name ORDER BY s.session_id)) % 2 AS l2,
			--(DENSE_RANK() OVER (PARTITION BY s.session_id ORDER BY c.connection_id)) % 2 AS l3,
			--(ROW_NUMBER () OVER (PARTITION BY s.session_id,c.connection_id ORDER BY r.request_id)) % 2 AS l4,
			s.session_id,
			s.login_time,
			s.[host_name],
			s.[program_name],
			s.cpu_time AS cpu_time,
			s.memory_usage * 8 AS memory_usage,
			s.total_scheduled_time AS total_scheduled_time,
			s.total_elapsed_time AS total_elapsed_time,
			s.last_request_end_time,
			s.reads, 
			s.writes,
			s.login_name,
			s.nt_domain,
			s.nt_user_name,
			Convert(CHAR(100), c.connection_id) AS connection_id,
			c.connect_time,
			c.num_reads,
			c.num_writes,
			c.last_read,
			c.last_write,
			c.client_net_address,
			c.client_tcp_port,
			c.session_id,
			Convert(CHAR(100), r.request_id) AS request_id,
			r.start_time,
			r.command,
			r.open_transaction_count,
			r.open_resultset_count,
			r.percent_complete,
			r.estimated_completion_time,
			r.reads,
			r.writes,
			CASE
				WHEN r.[sql_handle] IS NOT NULL THEN (SELECT TOP 1 SubString(t2.[text], (r.statement_start_offset + 2) / 2, ((
					CASE 
						WHEN r.statement_end_offset = -1 THEN ((Len(Convert(NVARCHAR(MAX), t2.[text]))) * 2) 
						ELSE r.statement_end_offset 
					END) - r.statement_start_offset) / 2) FROM sys.dm_exec_sql_text(r.[sql_handle]) t2)
				ELSE ' '
			END AS sql_statement
		FROM sys.dm_exec_sessions s
			LEFT OUTER JOIN sys.dm_exec_connections c  ON ( s.session_id = c.session_id )
			LEFT OUTER JOIN sys.dm_exec_requests r  ON (r.session_id = c.session_id and r.connection_id = c.connection_id)
		WHERE s.is_user_process = 1

END TRY
BEGIN CATCH
	SELECT 
		---100 AS l1
		--1 AS l2,
		--1 AS l3,
		--1 AS l4,
		1 AS session_id,
		1 AS login_time,
		1 AS [host_name],
		1 AS [program_name],
		1 AS cpu_time,
		1 AS memory_usage,
		1 AS total_scheduled_time,
		1 AS total_elapsed_time,
		1 AS last_request_end_time,
		1 AS reads,
		1 AS writes,
		1 AS login_name,
		1 AS nt_domain,
		1 AS nt_user_name,
		1 AS connection_id,
		1 AS connect_time,
		1 AS num_reads,
		1 AS num_writes,
		1 AS last_read,
		1 AS last_write,
		1 AS client_net_address,
		1 AS client_tcp_port,
		1 AS session_id_1,
		1 AS request_id,
		1 AS start_time,
		1 AS command,
		1 AS open_transaction_count,
		1 AS open_resultset_count,
		1 AS percent_complete,
		ERROR_NUMBER() AS estimated_completion_time,
		ERROR_SEVERITY() AS reads_1,
		ERROR_STATE() AS writes_1,
		ERROR_MESSAGE() AS  sql_statement
END CATCH