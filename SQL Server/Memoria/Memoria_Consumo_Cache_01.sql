set nocount on
set transaction isolation level read uncommitted

;with hitcount as (
	select 
			[instance_name],  
			[cntr_value] 
		from sys.dm_os_performance_counters s 
        where [counter_name] = 'cache hit ratio' and [object_name] like '%:plan cache%'
), 
total as (
	select 
			[instance_name],  
			[cntr_value] 
		from sys.dm_os_performance_counters 
        where [counter_name] = 'cache hit ratio base' and [object_name] like '%:plan cache%'
), 
pages as (
	select 
			[instance_name], 
			[cntr_value] 
		from sys.dm_os_performance_counters 
        where [object_name] like '%:plan cache%' and [counter_name] = 'cache pages'
)
select 
		rtrim(hitcount.[instance_name]) as instance_name,
		cast((hitcount.[cntr_value] * 1.0 / (1 + total.[cntr_value])) * 100.0 as decimal(5, 2)) as hit_ratio_percent,
		([pages].[cntr_value] * 8 / 1024 ) as cache_mb
	from hitcount 
		join total on hitcount.[instance_name] = [total].[instance_name] 
		join pages on hitcount.[instance_name] = [pages].[instance_name] 
	order by hit_ratio_percent