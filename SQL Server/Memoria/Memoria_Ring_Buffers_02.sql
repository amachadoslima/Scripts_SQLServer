select top 100
	convert(varchar(30), getdate(), 121) as [runtime],
    dateadd(ms, (rbf.[timestamp] - tme.ms_ticks), getdate()) as time_stamp,
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(50)') as [action], 
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/RecordSource)[1]', 'varchar(50)') as [source], 
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/Spid)[1]', 'int') as [spid],
    msg.[description],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/RemoteHost)[1]', 'varchar(100)') as [remotehost],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/RemotePort)[1]', 'varchar(25)') as [remoteport],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/LocalPort)[1]', 'varchar(25)') as [localport],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferError)[1]', 'varchar(25)') as [tds_input_buffer_error],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsOutputBufferError)[1]', 'varchar(25)') as [tds_output_buffer_error],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferBytes)[1]', 'varchar(25)') as [tds_input_buffer_bytes],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/PhysicalConnectionIsKilled)[1]', 'int') as [is_phys_conn_killed], 
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/DisconnectDueToReadError)[1]', 'int') as [disconnect_dueto_read_error],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NetworkErrorFoundInInputStream)[1]', 'int') as [network_error_found],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/ErrorFoundBeforeLogin)[1]', 'int') as [error_before_login],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/SessionIsKilled)[1]', 'int') as [is_session_killed],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalDisconnect)[1]', 'int') as [normal_disconnect],
    cast(record as xml).value('(//Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalLogout)[1]', 'int') as [normal_logout],
    cast(record as xml).value('(//Record/@id)[1]', 'bigint') as [record_id], 
    cast(record as xml).value('(//Record/@type)[1]', 'varchar(30)') as [type], 
    cast(record as xml).value('(//Record/@time)[1]', 'bigint') as [record_time],
    tme.ms_ticks as [current_time]
	from sys.dm_os_ring_buffers rbf
		cross join sys.dm_os_sys_info tme
		cross join sys.sysmessages msg
	where rbf.ring_buffer_type = 'RING_BUFFER_CONNECTIVITY' 
		--and cast(record as xml).value('(//Record/ConnectivityTraceRecord/Spid)[1]', 'int') <> 0
	order by rbf.[timestamp] desc