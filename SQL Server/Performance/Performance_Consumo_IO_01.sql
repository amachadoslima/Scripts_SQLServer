USE master
GO

If(Object_ID(N'tempdb..#IOStatistics') IS NOT NULL)
	DROP TABLE #IOStatistics;
	 
DECLARE @Dml NVARCHAR(MAX)
 
DECLARE @IOStatistics TABLE
(
	[I/ORank] [int] NULL,
	[DBName] [nvarchar](128) NULL,
	[DriveLetter] [nvarchar](1) NULL,
	[TotalNumOfWrites] [bigint] NULL,
	[TotalNumOfBytesWritten] [bigint] NULL,
	[TotalNumOfReads] [bigint] NULL,
	[TotalNumOfBytesRead] [bigint] NULL,
	[TotalI/O(MB)] [decimal](15,2) NULL,
	[I/O(%)] [decimal](5, 2) NULL,
	[SizeOfFile] [decimal](10,2) NULL
)

Set @Dml =
'
WITH SQLShackIOStatistics AS
(
	SELECT 
			DB_Name(MF.database_id) AS DBName, 
			Left(MF.physical_name, 1) AS DriveLetter, 
			Sum(VFS.num_of_writes) [TotalNumOfWrites],
			Sum(VFS.num_of_bytes_written) [TotalNumOfBytesWritten],
			Sum(VFS.num_of_reads) [TotalNumOfReads], 
			Sum(VFS.num_of_bytes_read) [TotalNumOfBytesRead], 
			Cast(Cast(Sum(num_of_bytes_read + num_of_bytes_written) AS BIGINT) / 1024 AS DECIMAL(14, 2)) AS [TotIO(MB)],
			Max(Cast(VFS.size_on_disk_bytes / 1024 / 1024.00 AS DECIMAL(10,2))) SizeMB
		FROM sys.master_files MF
			JOIN sys.dm_io_virtual_file_stats(null, null) VFS ON MF.database_id = VFS.database_id AND MF.file_id = VFS.file_id
		GROUP BY MF.database_id, Left(MF.physical_name, 1)
)
SELECT 
		ROW_NUMBER() OVER(ORDER BY [TotIO(MB)] DESC) AS [I/ORank],
		[DBName],
		DriveLetter,
		[TotalNumOfWrites],
		TotalNumOfBytesWritten,
		TotalNumOfReads,
		TotalNumOfBytesRead,
		[TotIO(MB)] AS [I/O(MB)],
		Cast([TotIO(MB)]/ Sum([TotIO(MB)]) OVER() * 100.0 AS DECIMAL(5,2)) AS [I/O(%)],
		SizeMB
	FROM SQLShackIOStatistics
	ORDER BY [I/ORank]
	OPTION (RECOMPILE)
'
INSERT INTO @IOStatistics
	EXEC sp_executesql @Dml

SELECT 
		[DBName],
		[I/O Rank] = Stuff((
			SELECT ',' + Cast(S.[I/ORank] AS VARCHAR(3))
				FROM @IOStatistics S
				WHERE S.[DBName] = T.[DBName]
			FOR XML PATH('')), 1, 1, ''),
		PhysicalName = Stuff((
			SELECT ',' + S.DriveLetter
				FROM @IOStatistics S
				WHERE S.[DBName] = T.[DBName]
			FOR XML PATH('')), 1, 1, ''),
		FileSizeMB = Stuff((
			SELECT ',' + Cast(S.SizeOfFile AS VARCHAR(20))
				FROM @IOStatistics S
				WHERE S.[DBName] = T.[DBName]
			FOR XML PATH('')), 1, 1, ''),
		TotalNumOfWrites = Stuff((
			SELECT ',' + Cast(S.[TotalNumOfWrites] AS VARCHAR(20))
				FROM @IOStatistics S
				WHERE S.[DBName] = T.[DBName]
			FOR XML PATH('')), 1, 1, ''),
		TotalNumOfBytesWritten = Stuff((
			SELECT ',' + Cast(S.[TotalNumOfBytesWritten] AS VARCHAR(20))
			FROM @IOStatistics S
				WHERE S.[DBName] = T.[DBName]
			FOR XML PATH('')), 1, 1, ''),
		TotalNumOfReads = Stuff((
			SELECT ',' + Cast(S.TotalNumOfReads AS VARCHAR(20))
				FROM @IOStatistics S
				WHERE S.[DBName] = T.[DBName]
			FOR XML PATH('')), 1, 1, ''),
		TotalNumOfBytesReads = Stuff((
			SELECT ',' + Cast(S.TotalNumOfBytesRead AS VARCHAR(20))
				FROM @IOStatistics S
				WHERE S.[DBName] = T.[DBName]
			FOR XML PATH('')), 1, 1, ''),
		[Total I/O (MB)] = Stuff((
				SELECT ',' + Cast(S.[TotalI/O(MB)] AS VARCHAR(20))
					FROM @IOStatistics S
					WHERE S.[DBName] = T.[DBName]
				FOR XML PATH('')), 1, 1, ''),
		[I/O Percent] = Stuff((
			SELECT ',' + Cast(S.[I/O(%)] AS VARCHAR(20))
				FROM @IOStatistics S
				WHERE S.[DBName] = T.[DBName]
			FOR XML PATH('')), 1, 1, '')
	INTO #IOStatistics
	FROM @IOStatistics T
	GROUP BY [DBName]

SELECT * 
	FROM #IOStatistics
	--ORDER BY Cast([I/O Percent] AS DECIMAL(10,2)) DESC
	ORDER BY [I/O Rank] ASC

If(Object_ID(N'tempdb..#IOStatistics') IS NOT NULL)
	DROP TABLE #IOStatistics;