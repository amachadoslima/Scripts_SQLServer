declare @value int
declare @cnrt int
declare @memorymax int

select @memorymax = cast(value_in_use as int) from sys.configurations where lower([name]) = 'max server memory (mb)'
select @value = (((@memorymax / 1024) / 4) * 300)

select @cnrt = cntr_value 
	from sys.dm_os_performance_counters
	where lower([object_name]) like '%buffer manager%'
		and lower(counter_name) = 'page life expectancy'

select
	case when @cnrt > @value then 'HIGH PAGE LIFE EXPECTANCY' 
		 when @cnrt <= @value then 'LOW PAGE LIFE EXPECTANCY' end as [Status],
	@cnrt as cnrt_value, 
	@value as data_cache