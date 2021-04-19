USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

	SELECT  
			s.session_id,
			s.login_time,
			s.host_name,
			s.program_name,
			s.cpu_time AS cpu_time,
			s.memory_usage * 8 AS memory_usage,
			s.total_scheduled_time AS total_scheduled_time,
			s.total_elapsed_time AS total_elapsed_time,
			s.last_request_end_time,
			s.reads,
			s.writes,
			COUNT(c.connection_id) AS conn_count
		FROM sys.dm_exec_sessions s
			LEFT OUTER JOIN sys.dm_exec_connections c ON ( s.session_id = c.session_id )
			LEFT OUTER JOIN sys.dm_exec_requests r ON ( r.session_id = c.session_id )
		WHERE (s.is_user_process = 1)
			AND (s.session_id <> @@SPID)
		GROUP BY s.session_id, s.login_time, s.[host_name], s.cpu_time, s.memory_usage, s.total_scheduled_time, 
				 s.total_elapsed_time, s.last_request_end_time, s.reads, s.writes, s.[program_name]
		--ORDER BY s.writes DESC			-- Escritas
		--ORDER BY s.reads DESC			-- Leituras
		--ORDER BY s.memory_usage DESC	-- Uso de Memória
		--ORDER BY s.cpu_time DESC		-- Consumo de CPU
		ORDER BY s.login_time ASC	-- Conexões mais Antigas
END TRY
BEGIN CATCH
	SELECT 
			1 AS session_id, 
			1 AS login_time, 
			1 AS [host_name], 
			1 AS [program_name],
			-100 AS cpu_time,
			1 AS memory_usage,1 AS total_scheduled_time,1 AS total_elasped_time,
			ERROR_NUMBER() AS last_request_end_time,
			ERROR_SEVERITY()  AS reads,
			ERROR_STATE() AS writes,
			ERROR_MESSAGE() AS conn_count
END CATCH
