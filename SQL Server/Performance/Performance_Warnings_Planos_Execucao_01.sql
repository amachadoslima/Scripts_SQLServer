select 
		b.[text] as [sql_text], 
		c.query_plan as [query_plan]
	from
		(
			select top 50 *
				from sys.dm_exec_query_stats
				order by total_worker_time desc
		) as a
	cross apply sys.dm_exec_sql_text(a.sql_handle) as b
	cross apply sys.dm_exec_query_plan(a.plan_handle) as c
	where c.query_plan.value('declare namespace p="http://schemas.microsoft.com/sqlserver/2004/07/showplan";count(//p:Warnings)', 'int') > 0