--SELECT 
--		vfs.database_id, 
--		df.[name], 
--		df.physical_name,
--		vfs.[file_id], 
--		ior.io_pending
--	FROM sys.dm_io_pending_io_requests ior
--		JOIN sys.dm_io_virtual_file_stats (DB_ID(), NULL) vfs ON (vfs.file_handle = ior.io_handle)
--		JOIN sys.database_files df ON (df.[file_id] = vfs.[file_id]);
SELECT
		DB_Name(mf.database_id) as [database],
		mf.physical_name,
		ipir.io_type,
		Sum(ipir.io_pending) total_pending_io,
		Sum(ipir.io_pending_ms_ticks) total_pending_ms_ticks,
		Sum(vfs.num_of_reads) total_reads,
		Sum(vfs.num_of_writes) total_writes
	FROM sys.dm_io_pending_io_requests AS ipir
		JOIN sys.dm_io_virtual_file_stats(null,null) AS vfs ON ipir.io_handle = vfs.file_handle
		JOIN sys.master_files AS mf ON vfs.database_id = mf.database_id AND vfs.[file_id] = mf.[file_id]
	GROUP BY mf.database_id, mf.physical_name, ipir.io_type
	ORDER BY Sum(ipir.io_pending)
GO
SELECT    
		ipir.io_type, 
		ipir.io_pending,
		ipir.scheduler_address, ipir.io_handle,
		os.scheduler_id, os.cpu_id, os.pending_disk_io_count,
		er.session_id, 
		er.command, 
		er.cpu_time, 
		st.[text],
		db_name(er.database_id) as [db_name],
		er.blocking_session_id, 
		os.runnable_tasks_count,
		er.wait_time,
		os.failed_to_create_worker
	FROM sys.dm_io_pending_io_requests ipir
		INNER JOIN sys.dm_os_schedulers os ON ipir.scheduler_address = os.scheduler_address
		INNER JOIN sys.dm_exec_requests AS er ON os.scheduler_id = er.Scheduler_id
		CROSS APPLY sys.dm_exec_sql_text(er.[sql_handle]) AS st
	WHERE er.session_id <> @@SPID 
		AND io_pending > 0