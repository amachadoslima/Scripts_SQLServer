select top 10
		(qs.total_logical_reads + qs.total_logical_writes) as 'total_io',
		((qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count) as 'average_io',
		qs.execution_count,
		substring(qt.text, (qs.statement_start_offset / 2) + 1,
			((case when qs.statement_end_offset = -1
				then len(convert(nvarchar(max), qt.text)) * 2 else qs.statement_end_offset end - qs.statement_start_offset)/2) + 1) as 'individual_query',
		qt.text as 'parent_query',
		db_name(qt.[dbid]) as 'database_name',
		qp.query_plan
	from sys.dm_exec_query_stats qs
		cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
		cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
	order by 'total_io' desc