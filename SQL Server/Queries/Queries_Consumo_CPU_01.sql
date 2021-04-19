select top 30
		substring(t.text,
		(s.statement_start_offset / 2) + 1,
			((case s.statement_end_offset 
					when -1 then datalength(t.[text])  
					else s.statement_end_offset
					end - s.statement_start_offset) / 2) + 1) as 'individual query',
		t.[text] as 'parent_query',
		s.execution_count,
		s.total_logical_reads,
		s.last_logical_reads,
		s.total_logical_writes,
		s.last_logical_writes,
		s.total_worker_time,
		s.last_worker_time,
		(s.total_elapsed_time / 1000000)	as total_elapsed_time_secs,
		(s.last_elapsed_time / 1000000)	as last_elapsed_time_secs,
		s.last_execution_time,
		p.query_plan
	from sys.dm_exec_query_stats s
		cross apply sys.dm_exec_sql_text(s.[sql_handle]) t
		cross apply sys.dm_exec_query_plan(s.plan_handle) p
	order by s.total_worker_time, last_execution_time desc