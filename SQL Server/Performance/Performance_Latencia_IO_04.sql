USE master 
GO
BEGIN

	SET NOCOUNT ON

	-- DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR)
	/*
		melhor cenário possível: < 1ms
		ótimo: < 5ms
		bom: 5 – 10ms
		ruim: 10 – 20ms
		horroroso: 20 – 100ms
		vergonhosamente ruim: 100 – 500ms
		SOS: > 500ms
	*/

	If(OBJECT_ID(N'tempdb..#DiskInformation') IS NOT NULL)
		DROP TABLE #DiskInformation

	CREATE TABLE #DiskInformation
	(
		Disk_Drive char(100),
		Disk_DB sysname,
		Disk_Physical_Name sysname,
		Disk_Num_Of_Reads  bigint, 
		Disk_IO_Stall_Read_MS  bigint,  
		Disk_Num_Of_Writes bigint , 
		Disk_IO_Stall_Write_MS bigint , 
		Disk_Num_Of_Bytes_Read bigint, 
		Disk_Num_Of_Bytes_Written  bigint, 
		Disk_IO_Stall bigint
	)

	INSERT INTO #DiskInformation
		SELECT 
				Left(Upper(mf.physical_name), 2) AS Disk_Drive,
				DB_Name(vfs.database_id) AS Disk_DB,
				mf.[physical_name] AS Disk_Physical_Name,
				Sum(num_of_reads) AS Disk_Num_Of_Reads,
				Sum(io_stall_read_ms) AS Disk_IO_Stall_Read_MS, 
				Sum(num_of_writes) AS Disk_Num_Of_Writes,
				Sum(io_stall_write_ms) AS Disk_IO_Stall_Write_MS, 
				Sum(num_of_bytes_read) AS Disk_Num_Of_Bytes_Read,
				Sum(num_of_bytes_written) AS Disk_Num_Of_Bytes_Written, 
				Sum(io_stall) AS Disk_IO_Stall
			FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
				JOIN sys.master_files AS mf WITH (NOLOCK) ON vfs.database_id = mf.database_id AND vfs.[file_id] = mf.[file_id]
			WHERE Upper(mf.physical_name) NOT LIKE '%.ldf'
			GROUP BY Left(Upper(mf.physical_name), 2), vfs.database_id, mf.[physical_name]

	SELECT 
			Disk_DB,
			Disk_Physical_Name,
			CASE 
				WHEN Disk_Num_Of_Reads = 0 THEN 0 
				ELSE (Disk_IO_Stall_Read_MS / Disk_Num_Of_Reads) 
			END AS [Read Latency],
			CASE 
				WHEN Disk_IO_Stall_Write_MS = 0 THEN 0 
				ELSE (Disk_IO_Stall_Write_MS / Disk_Num_Of_Writes) 
			END AS [Write Latency],
			CASE 
				WHEN (Disk_Num_Of_Reads = 0 AND Disk_Num_Of_Writes = 0) THEN 0 
				ELSE (Disk_IO_Stall / (Disk_Num_Of_Reads + Disk_Num_Of_Writes)) 
			END AS [Overall Latency],
			CASE 
				WHEN Disk_Num_Of_Reads = 0 THEN 0 
				ELSE (Disk_Num_Of_Bytes_Read / Disk_Num_Of_Reads) 
			END AS [Avg Bytes/Read],
			CASE 
				WHEN Disk_IO_Stall_Write_MS = 0 THEN 0 
				ELSE (Disk_Num_Of_Bytes_Written / Disk_Num_Of_Writes) 
			END AS [Avg Bytes/Write],
			CASE 
				WHEN (Disk_Num_Of_Reads = 0 AND Disk_Num_Of_Writes = 0) THEN 0 
				ELSE ((Disk_Num_Of_Bytes_Read + Disk_Num_Of_Bytes_Written) / (Disk_Num_Of_Reads + Disk_Num_Of_Writes)) 
			END AS [Avg Bytes/Transfer]
	FROM #DiskInformation
	ORDER BY [Overall Latency]
	OPTION(RECOMPILE);	
	
	If(OBJECT_ID(N'tempdb..#DiskInformation') IS NOT NULL)
		DROP TABLE #DiskInformation
END
