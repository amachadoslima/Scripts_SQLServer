if object_id('tempdb..#info') is not null
	drop table #info

create table #info (
    [database_name]	varchar(128),
    [name]			varchar(128),
    [file_id]		int,
    [file_name]		varchar(1000),
    [file_group]	varchar(128),
    size			varchar(25),
    max_size		varchar(25),
    growth			varchar(25),
    usage			varchar(25)
)
 

insert into #info
	exec master.dbo.sp_MSforeachdb 'use [?] 
		select
			''?''
			,name
			,fileid
			,filename
			,filegroup = filegroup_name(groupid)
			,''size'' = convert(nvarchar(15), convert (bigint, size) * 8) + N'' kb''
			,''maxsize'' = 
				(case maxsize when -1 then N''unlimited''
				else ''limited '' + convert(nvarchar(15), convert (bigint, maxsize) * 8) + N'' kb'' end)
			,''growth'' = 
				(case status & 0x100000 when 0x100000 then convert(nvarchar(15), growth) + N''%''
				else convert(nvarchar(15), convert (bigint, growth) * 8) + N'' kb'' end)
			,''usage'' = (case status & 0x40 when 0x40 then ''log only'' else ''data only'' end)
		from
			sysfiles
		'
GO

select 
		[database_name],
		db_id([database_name]) as [dbid],
		[name] as [logical_name],
		[file_name] as [physical_file_name],
		(growth + ' ' + max_size) as [auto_grow_setting]
	from  #info 
	--where --	(lower(usage) = 'data only' and lower(growth) = '1024 kb') or	(lower(usage) = 'log only'  and lower(growth) = '10%')
	order by [dbid] desc

if object_id('tempdb..#info') is not null
	drop table #info