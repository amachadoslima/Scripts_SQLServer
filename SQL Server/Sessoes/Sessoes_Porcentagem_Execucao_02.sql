USE master 
BEGIN
	
	SELECT 
			command AS Command,
			S.[text] AS [Text],
			start_time AS [StartTime],
			percent_complete AS [PercentComplete], 
			RunningTime = CAST(((DATEDIFF(s, start_time, GETDATE())) / 3600) AS VARCHAR) + ' Hora(S), ' +
						  CAST((DATEDIFF(s, start_time, GETDATE()) % 3600) / 60 AS VARCHAR) + ' Min, ' +
						  CAST((DATEDIFF(s, start_time, GETDATE()) % 60) AS VARCHAR) + ' Seg',
			EstTimeToGo = CAST((estimated_completion_time / 3600000) AS VARCHAR) + ' Hora(S), ' +
						  CAST((estimated_completion_time % 3600000) / 60000 AS VARCHAR) + ' Min, ' +
						  CAST((estimated_completion_time % 60000) / 1000 AS VARCHAR) + ' Seg',
			EstCompletionTime = DATEADD(SECOND, estimated_completion_time / 1000, GETDATE())  
		FROM sys.dm_exec_requests R
			CROSS APPLY sys.dm_exec_sql_text(R.[sql_handle]) S
		WHERE percent_complete > 0
END