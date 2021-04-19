select top 100
		convert(varchar(30), getdate(), 121) as [run_time],
		dateadd(ms, (rbf.[timestamp] - tme.ms_ticks), getdate()) as time_stamp,
		cast(record as xml).value('(//Exception//Error)[1]', 'varchar(255)') as [error],
		cast(record as xml).value('(//Exception/Severity)[1]', 'varchar(255)') as [severity],
		cast(record as xml).value('(//Exception/State)[1]', 'varchar(255)') as [state],
		msg.[description],
		cast(record as xml).value('(//Exception/UserDefined)[1]', 'int') as [isuser_defined_error],
		cast(record as xml).value('(//Record/@id)[1]', 'bigint') as [record_id],
		cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') as [type], 
		cast(record as xml).value('(//Record/@time)[1]', 'bigint') as [record_time],
		tme.ms_ticks as [current_time]
	from sys.dm_os_ring_buffers rbf
		cross join sys.dm_os_sys_info tme
		cross join sys.sysmessages msg
	where rbf.ring_buffer_type = 'RING_BUFFER_EXCEPTION' 
			--AND cast(record as xml).value('(//SPID)[1]', 'int') <> 0 --IN (122,90,161,179)
			and msg.error = cast(record as xml).value('(//Exception//Error)[1]', 'varchar(500)') 
			and msg.msglangid = 1033 --and [error] = 4002
	order by rbf.[timestamp] desc