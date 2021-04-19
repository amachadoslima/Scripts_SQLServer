use master 
go
select top 100
		substring(qt.[text], (qs.statement_start_offset / 2) + 1, ((
			case qs.statement_end_offset
				when -1 then datalength(qt.[text])
				else qs.statement_end_offset
				end - qs.statement_start_offset) / 2) + 1) as [sql_text],
		qs.execution_count,
		qs.total_logical_reads,
		qs.last_logical_reads,
		qs.min_logical_reads,
		qs.max_logical_reads,
		qs.total_elapsed_time,
		qs.last_elapsed_time,
		qs.min_elapsed_time,
		qs.max_elapsed_time,
		qs.last_execution_time,
		qp.query_plan
	from sys.dm_exec_query_stats qs
		cross apply sys.dm_exec_sql_text(qs.[sql_handle]) qt
		cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
	where qt.encrypted = 0
	order by qs.last_logical_reads desc 