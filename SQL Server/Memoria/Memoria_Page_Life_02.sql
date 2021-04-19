declare @value int
declare @cnrt int

select @value = cast((cast((count(*) * 8 / 1024. / 1024.) as decimal(10,2)) / 4) * 300 as int)
	from sys.dm_os_buffer_descriptors

select @cnrt = cntr_value 
	from sys.dm_os_performance_counters
	where lower([object_name]) like '%buffer manager%'
		and lower(counter_name) = 'page life expectancy'

select
	case when @cnrt > @value then 'HIGH PAGE LIFE EXPECTANCY' 
		 when @cnrt <= @value then 'LOW PAGE LIFE EXPECTANCY' end as Status