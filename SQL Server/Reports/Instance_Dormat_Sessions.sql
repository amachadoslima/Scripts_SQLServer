USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

		SELECT 'All Sessions' AS [Status], COUNT(DISTINCT s.session_id) AS [Count]
			FROM sys.dm_exec_sessions s
			WHERE is_user_process = 1
	UNION
		SELECT 'Dormat Sessions (1+ hrs.)' AS [Status], COUNT(DISTINCT s.session_id) AS [Count]
            FROM sys.dm_exec_sessions s
            WHERE [status] = 'sleeping' 
				AND DateDiff(mi, last_request_end_time, GetDate()) >= 60
	UNION
		SELECT 'Users with Dormant Sessions (1+ hrs.)' AS [Status], COUNT(DISTINCT s.session_id) AS [Count]
            FROM sys.dm_exec_sessions s
            WHERE [status] = 'sleeping' 
				AND DateDiff(mi, last_request_end_time, GetDate()) >= 60
				AND is_user_process = 1
END TRY
BEGIN CATCH
	SELECT 'All Sessions' AS [Status], NULL AS [Count]
	UNION
	SELECT 'Dormat Sessions (1+ hrs.)' AS [Status], NULL AS [Count]
	UNION
	SELECT 'Users with Dormant Sessions (1+ hrs.)' AS [Status], NULL AS [Count]
END CATCH
GO
-- TOP 10 USUÁRIOS COM SESSÕES COM STATUS DORMENT
BEGIN TRY

	DECLARE @D1 DATETIME
	set @D1 = getdate();

	SELECT TOP 10  
			s.login_name AS [User Name],
			(DateDiff(mi, Min(s.last_request_end_time), @D1)) / 60 AS [Last Activy Hrs.],
			Min(s.last_request_end_time) AS [Last Activity],
			(SELECT COUNT(*)
				FROM  sys.dm_exec_sessions s2
				WHERE s2.login_name = s.login_name
					AND	is_user_process = 1	
			) AS [All Sessions],
			COUNT(*) AS [Dormant Sessions], 
			Sum(CASE WHEN DateDiff(mi,s.last_request_end_time, @D1) >= 60 THEN 1 ELSE 0 END) AS [Dormat Sessions hrs.]
		FROM  sys.dm_exec_sessions s
		WHERE s.is_user_process = 1 AND 
			[status] = 'sleeping'
			--AND s.last_request_end_time IS NOT NULL
			--AND s.last_request_start_time <= s.last_request_end_time
		GROUP BY s.login_name
		ORDER BY [Dormant Sessions] DESC, [All Sessions] DESC

END TRY
BEGIN CATCH
	SELECT
		0 AS login_name,
		ERROR_NUMBER() AS duration,
		ERROR_SEVERITY() AS oldest_time,
		ERROR_STATE() AS TotalSessions,
		ERROR_MESSAGE() AS DormantSessions,
		-100 AS DormantSessionshr
END CATCH
GO
-- TOP 10 SESSÕES COM STATUS DORMANT
BEGIN TRY

	DECLARE @D1 DATETIME
	DECLARE @TabSId TABLE(session_id SMALLINT)

	Set @D1 = getdate();

	INSERT INTO @TabSId
		SELECT TOP 10 session_id
			FROM sys.dm_exec_sessions
			WHERE is_user_process = 1
				AND [status] = 'sleeping'
				--AND last_request_end_time IS NOT NULL
				--AND last_request_start_time < last_request_end_time
			ORDER BY last_request_end_time

	SELECT 
			s.session_id,
			s.login_time,
			s.[host_name],
			s.host_process_id,
			s.[program_name],
			s.login_name,
			s.is_user_process,
			s.last_request_end_time,
			(DateDiff(mi, s.last_request_end_time, @D1))/ 60 AS session_duration,
			COUNT(c.connection_id) AS connection_id,
			s.cpu_time,
			s.memory_usage * 8 AS memory_usage
		FROM @TabSId tt
			LEFT OUTER JOIN sys.dm_exec_sessions s ON (tt.session_id = s.session_id)
			LEFT OUTER JOIN sys.dm_exec_connections c ON (s.session_id = c.session_id)
		GROUP BY s.session_id,
				s.login_time,
				s.[host_name],
				s.host_process_id,
				s.[program_name],
				s.login_name,
				s.is_user_process,
				s.last_request_end_time,
				s.cpu_time,
				s.memory_usage
		ORDER BY last_request_end_time
END TRY
BEGIN CATCH
	SELECT 
		-100 AS session_id,
		ERROR_NUMBER() AS login_time,
		ERROR_SEVERITY() AS [host_name],
		ERROR_STATE() AS host_process_id,
		ERROR_MESSAGE() AS [program_name],
		0 AS login_name, 
		0 AS is_user_process,
		0 AS last_request_end_time,
		0 AS session_duration,
		0 AS connection_id, 
		0 AS cpu_time,
		0 AS memory_usage
END CATCH
