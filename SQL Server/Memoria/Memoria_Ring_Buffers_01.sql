select top 100
		convert(varchar(30), getdate(), 121) as [runtime],
		dateadd(ms, rbf.[timestamp] - tme.ms_ticks, getdate()) as [notification_time],
		cast(record as xml).value('(//SPID)[1]', 'bigint') as spid,
		msg.[description],
		cast(record as xml).value('(//ErrorCode)[1]', 'varchar(255)') as error_code,
		cast(record as xml).value('(//CallingAPIName)[1]', 'varchar(255)') as [calling_apin_ame],
		cast(record as xml).value('(//APIName)[1]', 'varchar(255)') as [api_name],
		cast(record as xml).value('(//Record/@id)[1]', 'bigint') as [record_id],
		cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') as [type],
		cast(record as xml).value('(//Record/@time)[1]', 'bigint') as [record_time],
		tme.ms_ticks as [current_time]
	from sys.dm_os_ring_buffers rbf
		cross join sys.dm_os_sys_info tme
		cross join sys.sysmessages msg
	where rbf.ring_buffer_type = 'RING_BUFFER_SECURITY_ERROR' 
			--cast(record as xml).value('(//SPID)[1]', 'int') = '147'
	order by rbf.[timestamp] desc