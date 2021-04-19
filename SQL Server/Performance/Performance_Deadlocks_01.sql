use master 
go
select 
       xed.value('@timestamp', 'datetime') as creation_date, 
       xed.query('.') as extend_event 
	from 
	( 
		select cast([target_data] as xml) as target_data 
			from sys.dm_xe_session_targets as xt 
				join sys.dm_xe_sessions as xs on xs.address = xt.event_session_address 
			where xs.name = N'system_health' 
			and xt.target_name = N'ring_buffer' 
	) as xml_data 
		cross apply target_data.nodes('RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData(xed) 
	order by creation_date desc