USE master 
GO
BEGIN

	declare @ts_now bigint

	select @ts_now = ms_ticks
		from sys.dm_os_sys_info

	select
			record_id,
			dateadd(ms, -1 * (@ts_now - [timestamp]), getdate()) AS EventTime,
			SQLProcessUtilization,
			SystemIdle,
			100 - SystemIdle - SQLProcessUtilization AS OtherProcessUtilization,
			UserModeTime,
			KernelModeTime,
			PageFaults,
			WorkingSetDelta,
			MemoryUtilPct
		from (
			select
					record.value('(./Record/@id)[1]', 'int') AS record_id,
					record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') AS SystemIdle,
					record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') AS SQLProcessUtilization,
					record.value('(./Record/SchedulerMonitorEvent/SystemHealth/UserModeTime)[1]', 'int') AS UserModeTime,
					record.value('(./Record/SchedulerMonitorEvent/SystemHealth/KernelModeTime)[1]', 'int') AS
					KernelModeTime,
					record.value('(./Record/SchedulerMonitorEvent/SystemHealth/PageFaults)[1]', 'int') AS PageFaults,
					record.value('(./Record/SchedulerMonitorEvent/SystemHealth/WorkingSetDelta)[1]', 'int') AS WorkingSetDelta,
					record.value('(./Record/SchedulerMonitorEvent/SystemHealth/MemoryUtilization)[1]', 'int') AS MemoryUtilPct,
					timestamp
				from (
					select
							timestamp,
							CONVERT(xml, record) AS record
					from sys.dm_os_ring_buffers
					where ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
						and record like '%<SystemHealth>%'
				) as x
		) as y
	where SQLProcessUtilization >= 50
	order by record_id desc

END