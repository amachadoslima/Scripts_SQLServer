WITH IOStats
AS
(
	SELECT 
			DB_NAME(database_id) AS [DB Name],
			CAST(SUM(num_of_bytes_read + num_of_bytes_written)/1048576 AS DECIMAL(12, 2)) AS IO_IN_MB
		FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS [DM_IO_STATS]
		GROUP BY database_id
)
SELECT 
		ROW_NUMBER() OVER(ORDER BY io_in_mb DESC) AS [I/O Rank], [DB Name], 
		IO_IN_MB AS [Total I/O (MB)],
		CAST(io_in_mb/ SUM(io_in_mb) OVER() * 100.0 AS DECIMAL(5,2)) AS [I/O Percent]
	FROM IOStats
	ORDER BY [I/O Rank] 