USE master 
GO

If(Object_ID(N'tempdb..#tmpLogSpace') IS NOT NULL)
	DROP TABLE #tmpLogSpace;

CREATE TABLE #tmpLogSpace
( 
	[DBName] sysname,
	LogSizeMB float,
	LogSpaceUsedPct float,
	[Status] int
);

INSERT INTO #tmpLogSpace
	EXEC ('DBCC SQLPERF(LOGSPACE);')

SELECT *
	FROM #tmpLogSpace
	--WHERE LogSpaceUsedPct > 95.