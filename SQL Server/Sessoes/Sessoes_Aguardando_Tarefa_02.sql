with [waits] as(
	select
		[wait_type],
        [wait_time_ms] / 1000.0 as [waits],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 as [resources],
        [signal_wait_time_ms] / 1000.0 as [signals],
        [waiting_tasks_count] as [waitcount],
		(100.0 * [wait_time_ms] / sum ([wait_time_ms]) over()) as [percentage],
        row_number() over(order by [wait_time_ms] desc) as [rownum]
    from sys.dm_os_wait_stats
    where [wait_type] not in 
	(
        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
        N'CHKPT', N'CLR_AUTO_EVENT',
        N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
 
        -- Maybe uncomment these four if you have mirroring issues
        N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
 
        N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC', N'FSAGENT',
        N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
 
        -- Maybe uncomment these six if you have AG issues
        N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
 
        N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT',
        N'ONDEMAND_TASK_QUEUE',
        N'PREEMPTIVE_XE_GETTARGETSTATE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'QDS_SHUTDOWN_QUEUE', N'REDO_THREAD_PENDING_WORK',
        N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
        N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
        N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
        N'WAIT_XTP_RECOVERY',
        N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
    AND [waiting_tasks_count] > 0
)
select
		max(w1.wait_type) as [waittype],
		cast(max(w1.waits) as decimal (16,2)) as [wait_s],
		cast(max(w1.resources) as decimal (16,2)) as [resource_s],
		cast(max(w1.signals) as decimal (16,2)) as [signal_s],
		max(w1.waitcount) as [waitcount],
		cast(max(w1.[percentage]) as decimal (5,2)) as [percentage],
		cast((max(w1.waits) / max(w1.waitcount)) as decimal (16,4)) as [avgwait_s],
		cast((max(w1.resources) / max(w1.waitcount)) as decimal (16,4)) as [avgres_s],
		cast((max(w1.signals) / max(w1.waitcount)) as decimal (16,4)) as [avgsig_s],
		cast('https://www.sqlskills.com/help/waits/' + max ([w1].[wait_type]) as xml) as [help/info url]
	from [waits] as w1
		join [waits] as w2 on [w2].[rownum] <= w1.rownum
	group by w1.rownum
	having sum (w2.[percentage]) - max(w1.[percentage]) < 95; -- percentage threshold
go