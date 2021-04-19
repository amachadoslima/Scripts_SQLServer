with xmlnamespaces('http://schemas.microsoft.com/sqlserver/2004/07/showplan' as p)
select b.text as [sql_text], c.query_plan as [query_plan]
	from (
		select top 50 *
			from sys.dm_exec_query_stats
			order by total_worker_time desc
	) as a
	cross apply sys.dm_exec_sql_text(a.sql_handle) as b
	cross apply sys.dm_exec_query_plan(a.plan_handle) as c
	cross apply c.query_plan.nodes( '//p:RelOp/p:Warnings[(@NoJoinPredicate[.="1"])]' ) as q(n) ;