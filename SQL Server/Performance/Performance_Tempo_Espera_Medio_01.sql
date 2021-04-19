;with cte as(
	select rn = row_number() over(partition by counter_name order by counter_name), counter_name, instance_name, cast(cntr_value as bigint) as cntr_value
		from sys.dm_os_performance_counters
		where lower(counter_name) = 'average wait time (ms)'
			and lower(instance_name) = '_total'
)
select * from cte
union
select rn = row_number() over(partition by counter_name order by instance_name asc) + 1, counter_name, instance_name, cast(cntr_value as bigint) as cntr_value
	from sys.dm_os_performance_counters
	where lower(counter_name) = 'average wait time (ms)'
		and lower(instance_name) <> '_total'
order by rn asc