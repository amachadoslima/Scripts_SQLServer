USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY
	SELECT TOP 20 
			RANK() OVER (ORDER BY total_logical_reads+total_logical_writes DESC, [sql_handle], statement_start_offset ) AS row_no,
			(RANK() OVER (ORDER BY total_logical_reads+total_logical_writes DESC, [sql_handle], statement_start_offset )) % 2 AS l1,
			creation_time,
			last_execution_time,
			Cast((total_worker_time + 0.0) / 1000 AS DECIMAL(10,2)) AS total_worker_time,
			Cast((total_worker_time + 0.0) / (execution_count * 1000) AS DECIMAL(10,2)) as [AvgCPUTime],
			total_logical_reads AS [LogicalReads],
			total_logical_writes AS [LogicalWrites],
			execution_count,
			total_logical_reads + total_logical_writes AS [AggIO],
			Cast((total_logical_reads + total_logical_writes) / (execution_count + 0.0) AS DECIMAL(10,2)) AS [AvgIO],
			CASE 
				WHEN [sql_handle] IS NULL THEN ' '
				ELSE(SubString(st.[text], (qs.statement_start_offset + 2) / 2, (
					CASE 
						WHEN qs.statement_end_offset = -1 THEN Len(Convert(NVARCHAR(MAX), st.[text])) * 2
						ELSE qs.statement_end_offset    
					END - qs.statement_start_offset) / 2))
			END AS query_text,
			DB_NAME(st.[dbid]) AS [database_name],
			st.objectid AS [object_id]
		FROM sys.dm_exec_query_stats qs
			CROSS APPLY sys.dm_exec_sql_text([sql_handle]) st
		WHERE total_logical_reads+total_logical_writes > 0 
		ORDER BY [AggIO] DESC
END TRY
BEGIN CATCH

	SELECT
		-100 AS row_no,
		1 AS l1, 1 AS creation_time, 
		1 AS last_execution_time,  
		1 AS total_worker_time,  
		1 AS Avg_CPU_Time, 
		1 AS logicalReads,  
		1 AS LogicalWrites,
		ERROR_NUMBER() AS execution_count,
		ERROR_SEVERITY() AS AggIO,
		ERROR_STATE() AS AvgIO,
		ERROR_MESSAGE() AS query_text 
END CATCH