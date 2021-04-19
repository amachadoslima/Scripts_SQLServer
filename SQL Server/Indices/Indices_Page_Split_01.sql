use SDBP12
go

set nocount on
begin try
	declare @ssql varchar(max)

	if (object_id(N'tempdb..#tmp_pagesplit') is not null)
		drop table #tmp_pagesplit;

	create table #tmp_pagesplit
	(
		 [db_name]			sysname		NOT NULL
		,num_slipt			int			NULL
		,alloc_unit_name	char(100)	NULL
		,context			char(100)	NULL
	);

	EXEC master.dbo.sp_MSforeachdb 
	'	USE [?];
		INSERT INTO #tmp_pagesplit
			SELECT
				DB_NAME(),
				COUNT(1) AS number_of_splits,
				allocunitname,
				context
			FROM
				fn_dblog(NULL,NULL)
			WHERE
				operation = ''LOP_DELETE_SPLIT''
			and allocunitname not like ''sys%''
			and allocunitname <> ''Unknown Alloc Unit''
			group by allocunitname, context
	'
	--SELECT * FROM #tmp_PageSplit ORDER BY NumSlipt DESC
	select 
			'use [' + [db_name] + '] ; ALTER INDEX [' + rtrim(parsename(alloc_unit_name, 1)) + '] ON [' + parsename(alloc_unit_name, 2) + '] REBUILD WITH(FILLFACTOR = 90, ONLINE = ON)' AS script, 
			num_slipt
		from #tmp_pagesplit
		where [db_name] <> 'tempdb'
		order by num_slipt desc
end try
begin catch
	select error_number() as err_num, error_message() as err_msg
end catch

if (object_id(N'tempdb..#tmp_pagesplit') is not null)
	drop table #tmp_pagesplit;