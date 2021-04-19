USE master 
BEGIN

	-- Insira o valor do trace a ser analisado!
	DECLARE @TraceID INT = 5

	-- Configurações básicas do trace:
	SELECT	
			CASE WHEN max_size IS NULL THEN '20' ELSE CONVERT(VARCHAR, max_size) END AS MaxFileSize,
			CASE WHEN max_files IS NULL THEN ' 5 ' ELSE CONVERT(VARCHAR, max_files) END AS MaxRolloverFiles,
			CASE WHEN stop_time IS NULL THEN NULL ELSE CONVERT(VARCHAR(40), stop_time, 121) END AS StopTime,
			CASE WHEN [path] IS NULL THEN 'N/A' ELSE Left([path], Len([path]) - 4) END AS [Path]
		FROM sys.traces 
		WHERE ID = @TraceID

	-- Todos os eventos configurados:
	SELECT
			 i.eventid AS [EventID],
			 i.columnid AS [ColumnID],
			 e.[name] + ', ' + c.[name] AS Descricao
		FROM ::fn_trace_geteventinfo(@TraceID) AS i
			JOIN sys.trace_events e ON i.eventid  = e.trace_event_id
			JOIN sys.trace_columns c ON i.columnid = c.trace_column_id
	
	-- Filtros configurados:
	SELECT 
			c.[name],
			--logical_operator AS [LogicalOperator],
			--comparison_operator AS [ComparisonOperator],
			CONVERT(VARCHAR(8000), [value]) + CASE WHEN logical_operator = 0 THEN ' AND ' ELSE ' OR ' END + c.[name] +
				CASE 
					WHEN comparison_operator = 0  THEN ' = '
					WHEN comparison_operator = 1  THEN ' <> '
					WHEN comparison_operator = 2  THEN ' > '
					WHEN comparison_operator = 3  THEN ' < '
					WHEN comparison_operator = 4  THEN ' >= '
					WHEN comparison_operator = 5  THEN ' <= '
					WHEN comparison_operator = 6  THEN ' LIKE '
					WHEN comparison_operator = 7  THEN ' NOT LIKE '
				END + CONVERT(VARCHAR(8000), [value]) AS [Filter]
		FROM ::fn_trace_getfilterinfo(@TraceID) f
			JOIN sys.trace_columns c ON f.columnid = c.trace_column_id
END