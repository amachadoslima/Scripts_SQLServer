select top 100 
		(qs.total_elapsed_time / 1000000.) as elapsed_sec, 
		(qs.total_worker_time / 1000000.) as worker_sec, 
		st.[text] as query, 
		*
	from sys.dm_exec_query_stats qs
		outer apply sys.dm_exec_sql_text(qs.[sql_handle]) st
	order by (qs.total_elapsed_time - qs.total_worker_time) desc