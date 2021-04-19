use sigero_admin
go
select top (50) 
		('[' + e.[name] + '].[' + d.[name] + ']') as [object],
		substring(b.[text], (a.statement_start_offset / 2) + 1, 
			((case a.statement_end_offset when -1 then datalength(b.[text]) else a.statement_end_offset end - a.statement_start_offset)/2)+1) as partoftext,
		a.execution_count,	a.total_logical_reads, a.last_logical_reads,
		a.total_logical_writes, a.last_logical_writes,
		a.total_worker_time,
		a.last_worker_time,
		a.total_elapsed_time/1000000 total_elapsed_time_in_s,
		a.last_elapsed_time/1000000 last_elapsed_time_in_s,
		a.last_execution_time,
		c.query_plan
	from sys.dm_exec_query_stats a
		cross apply sys.dm_exec_sql_text(a.[sql_handle]) b
		cross apply sys.dm_exec_query_plan(a.plan_handle) c
		left join sys.objects d on c.objectid = d.[object_id]
		left join sys.schemas e on d.[schema_id] = e.[schema_id]
	where c.number > 0
	order by a.last_physical_reads desc
	--order by a.total_logical_reads desc -- logical reads
	--order by a.total_logical_writes desc -- logical writes
	--order by a.total_worker_time desc -- cpu time