select top 50 
		'[' + d.[name] + '].[' + object_name(b.objectid) + ']' as [object_name], 
		(total_logical_reads / execution_count) as avg_logical_reads, 
		(total_logical_writes / execution_count) as avg_logical_writes ,
		(total_physical_reads / execution_count) as avg_physical_reads, 
		last_execution_time, total_rows, last_rows, min_rows, max_rows
	from sys.dm_exec_query_stats a 
		cross apply sys.dm_exec_sql_text(a.sql_handle) as b
		left join sys.objects c on b.objectid = c.[object_id]
		left join sys.schemas d on c.[schema_id] = d.[schema_id]
	where db_name(b.dbid) = 'sigero_admin'
		and last_execution_time > getdate() - 1 
	order by avg_physical_reads desc