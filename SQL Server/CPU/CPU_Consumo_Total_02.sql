declare @ms_ticks_now bigint

select @ms_ticks_now = ms_ticks
from sys.dm_os_sys_info;

select
		@@servername as instancia,
		record_id,
		dateadd(ms, - 1 * (@ms_ticks_now - [timestamp]), getdate()) as [event_time],
		[sql_process_utilization],
		[system_idle],
		(100 - [system_idle] - [sql_process_utilization]) as other_process_utilization
	from (
		select record.value('(./Record/@id)[1]', 'int') as record_id
			,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') as [system_idle]
			,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') as [sql_process_utilization]
			,[timestamp]
		from (
			select [timestamp], convert(xml, record) as record
				from sys.dm_os_ring_buffers
					where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
					and record like '%<SystemHealth>%'
			) as x
		) as y
	--where sqlprocessutilization > 50
	order by record_id asc