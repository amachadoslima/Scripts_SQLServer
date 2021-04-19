SELECT 

		plan_generation_num, 
		execution_count, 
		SubString(st.[text], qs.statement_start_offset / 2 + 1, (
			CASE statement_end_offset
				WHEN -1 THEN DataLength(st.[text])
				ELSE qs.statement_end_offset
			END - qs.statement_start_offset) / 2 + 1) AS statement_text
	FROM sys.dm_exec_query_stats AS qs
		CROSS APPLY sys.dm_exec_sql_text(qs.[sql_handle]) AS st
	WHERE plan_generation_num > 1
	ORDER BY plan_generation_num DESC;