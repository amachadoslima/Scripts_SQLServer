select 
		a.objtype as [cache_type],
		a.cacheobjtype as [cache_obj_type],
		count_big(*) as [total_plans],
		sum(cast(a.size_in_bytes as decimal(18, 2))) / 1024 / 1024 as [total mbs],
		avg(a.usecounts) as [avg_use_count],
		isnull(avg (datediff(minute, ph_time.creation_time, (getdate()))), 0) as [avg_age_in_minutes]
    from sys.dm_exec_cached_plans as a
    left join (
                select  plan_handle, min (creation_time) as creation_time --um plano pode ter várias peculiaridades relacionadas exclusivas, isso fica apenas uma vez por plano
					from sys.dm_exec_query_stats
					--where last_execution_time > getdate() - 1
					group by plan_handle
                ) as ph_time on a.plan_handle = ph_time.plan_handle
			--left join sys.dm_exec_query_stats on sys.dm_exec_cached_plans.plan_handle = sys.dm_exec_query_stats.plan_handle 
    group by objtype, cacheobjtype
    order by objtype, cacheobjtype-- [total mbs] desc

go

select *
	from sys.dm_os_performance_counters
	where [object_name] like '%manager%'
		and [counter_name] = 'page life expectancy'