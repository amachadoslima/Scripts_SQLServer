select 
		convert(varchar(30), getdate(), 121) as [run_time],
		dateadd(ms, (rbf.[timestamp] - tme.ms_ticks), getdate()) as [notification_time], 
		cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') as [notification_type], 
		cast(record as xml).value('(//Record/MemoryRecord/MemoryUtilization)[1]', 'bigint') as [memory_utilization_percent], 
		cast(record as xml).value('(//Record/MemoryNode/@id)[1]', 'bigint') as [node_id], 
		cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsProcess)[1]', 'int') as [process_indicator],
		cast(record as xml).value('(//Record/ResourceMonitor/IndicatorsSystem)[1]', 'int') as [system_indicator],
		cast(record as xml).value('(//Record/MemoryNode/ReservedMemory)[1]', 'bigint') as [sql_reserved_memory_kb], 
		cast(record as xml).value('(//Record/MemoryNode/CommittedMemory)[1]', 'bigint') as [sql_committed_memory_kb], 
		cast(record as xml).value('(//Record/MemoryNode/AWEMemory)[1]', 'bigint') as [sql_awe_memory], 
		cast(record as xml).value('(//Record/MemoryNode/SinglePagesMemory)[1]', 'bigint') as [single_pages_memory], 
		cast(record as xml).value('(//Record/MemoryNode/MultiplePagesMemory)[1]', 'bigint') as [multiple_pages_memory], 
		cast(record as xml).value('(//Record/MemoryRecord/TotalPhysicalMemory)[1]', 'bigint') as [total_physical_memory_kb], 
		cast(record as xml).value('(//Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') as [available_physical_memory_kb], 
		cast(record as xml).value('(//Record/MemoryRecord/TotalPageFile)[1]', 'bigint') as [total_pagefile_kb], 
		cast(record as xml).value('(//Record/MemoryRecord/AvailablePageFile)[1]', 'bigint') as [available_page_file_kb], 
		cast(record as xml).value('(//Record/MemoryRecord/TotalVirtualAddressSpace)[1]', 'bigint') as [total_virtual_addressspace_kb], 
		cast(record as xml).value('(//Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') as [available_virtual_addressspace_kb], 
		cast(record as xml).value('(//Record/@id)[1]', 'bigint') as [record_id], 
		cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') as [type],
		cast(record as xml).value('(//Record/@time)[1]', 'bigint') as record_time,
		tme.ms_ticks as [current_time]
	from sys.dm_os_ring_buffers rbf
		cross join sys.dm_os_sys_info tme
	where rbf.ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR' 
		--AND cast(record as xml).value('(//Record/ResourceMonitor/Notification)[1]', 'varchar(30)') = 'RESOURCE_MEMPHYSICAL_LOW'
	order by rbf.[timestamp] desc