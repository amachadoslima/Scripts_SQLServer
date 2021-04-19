USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY
	SELECT TOP 50
			(ROW_NUMBER() OVER(ORDER BY c.connect_time)) % 2 AS l1,
			Convert(CHAR(100), c.connection_id) AS connection_id,
			c.session_id,
			c.connect_time,
			c.num_reads,
			c.num_writes,
			c.last_read,
			c.last_write,
			c.client_net_address,
			c.client_tcp_port,
			(SELECT COUNT(*) FROM sys.dm_exec_requests r WHERE (r.connection_id = c.connection_id)) AS request_count,
			s.login_time,
			s.[host_name],
			s.[program_name],
			s.login_name,
			s.is_user_process
		FROM sys.dm_exec_connections c
			LEFT OUTER JOIN sys.dm_exec_sessions s ON (s.session_id = c.session_id)
		ORDER BY c.connect_time --CONEXÕES MAIS ANTIGAS
		--ORDER BY c.num_reads DESC -- POR LEITURAS
		--ORDER BY c.num_writes DESC -- POR ESCRITAS
END TRY
BEGIN CATCH
	SELECT 
		-100 AS l1,
		1 AS connection_id,
		1 AS session_id,
		1 AS connect_time,
		1 AS num_reads,
		1 AS num_writes,
		1 AS last_read,
		1 AS last_write,
		1 AS client_net_address,
		1 AS client_tcp_port,
		1 AS request_count,
		1 AS login_time,
		ERROR_NUMBER() AS [host_name],
		ERROR_SEVERITY() AS [program_name],
		ERROR_STATE() AS login_name,
		ERROR_MESSAGE() AS is_user_process
END CATCH