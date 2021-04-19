select 
		[counter_name] as countername,
		[cntr_value] as countervalue
	from sys.dm_os_performance_counters
	where [object_name] like ('%Database Mirroring%')
		and [counter_name] in ('Log Send Queue KB','Redo Queue KB')
		and [instance_name] = 'SDBP12'