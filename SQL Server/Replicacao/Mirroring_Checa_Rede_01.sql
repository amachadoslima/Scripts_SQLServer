select 
		instance_name, 
		counter_name, 
		cntr_value,
		case cntr_type 
			when 65792 then 'absolute meaning' 
			when 65536 then 'absolute meaning' 
			when 272696576 then 'per second counter and is cumulative in nature'
			when 1073874176 then 'bulk counter. to get correct value, this value needs to be divided by base counter value'
			when 537003264 then 'bulk counter. to get correct value, this value needs to be divided by base counter value' 
		end as counter_comments
	from sys.dm_os_performance_counters
	where lower([object_name])  = 'sqlserver:database mirroring'
		and lower(instance_name) <> '_total'
		and lower(counter_name) in('bytes received/sec', 'bytes sent/sec')
		and cntr_type not in(1073939712)
	order by counter_name, instance_name 
