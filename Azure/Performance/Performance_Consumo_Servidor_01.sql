select 
		cpu_idle = record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int'),
		cpu_sql = record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int'),
		memory_usage = record.value('(./Record/SchedulerMonitorEvent/SystemHealth/MemoryUtilization)[1]', 'int'),
		page_faults = record.value('(./Record/SchedulerMonitorEvent/SystemHealth/PageFaults)[1]', 'int')
	from (
		select top 1 convert(xml, record) as record
			from sys.dm_os_ring_buffers
			where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
				and record like '% %'
			order by [timestamp] desc
	) as cpu_usage