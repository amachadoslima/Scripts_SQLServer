if(object_id(N'tempdb..##tmpdbfiles') is not null)
	drop table tempdb..##tmpdbfiles;

create table ##tmpdbfiles
(
	dbname			sysname,
	drive			varchar(10),
	file_size_mb		decimal(10,2),
	space_used_mb	decimal(10,2),
	free_space_mb	decimal(10,2),
	[free_space%]	decimal(10,2),
	[name]			varchar(1000),
	[file_name]		varchar(1000)
)

exec master.dbo.sp_MSforeachdb N'
	
	USE [?];

	insert into ##tmpdbfiles
		select
			db_name(), 
			substring(a.filename, 1, 1),
			convert(decimal(12,2), round(a.size / 128.000, 2)),			
			convert(decimal(12,2), round(fileproperty(a.name,''spaceused'') / 128.000, 2)), 
			convert(decimal(12,2),
			round((a.size - fileproperty(a.name,''spaceused'')) / 128.000, 2)),
			convert(decimal(12,2),
			(convert(decimal(12,2), round((a.size - fileproperty(a.name,''spaceused'')) / 128.000, 2)) / convert(decimal(12,2), round(a.size / 128.000, 2)) * 100)),
			a.name, 
			a.filename
	from dbo.sysfiles a
'

select * 
	from tempdb..##tmpdbfiles
	--WHERE [free_space%] < 2
	--ORDER BY DBName ASC

if(object_id(N'tempdb..##tmpdbfiles') is not null)
	drop table tempdb..##tmpdbfiles;