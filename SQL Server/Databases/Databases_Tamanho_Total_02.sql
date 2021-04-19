declare @database nvarchar(100) = 'SIGERO_ADMIN'
declare @drive nvarchar(2) = null 
declare @cmd nvarchar(4000)

if (select object_id('tempdb.dbo.#dbname')) is not null
	drop table #dbname;

create table #dbname 
(
	dbname nvarchar(100)
)
 
if(@database is not null)
	insert into #dbname select @database
else
	insert into #dbname select name from sys.databases
 
if (select object_id('tempdb.dbo.##filestats')) is not null
	drop table ##filestats

create table ##filestats 
(
	server_name varchar(100), 
	[db_name] varchar(100), 
	file_type varchar(100), 
	[file_name] varchar(100), 
	[group_name] varchar(100),
	current_size_mb decimal(15,2), 
	space_used_mb decimal(15,2), 
	free_space_mb decimal(15,2), 
	percent_mb_free decimal(15,2), 
	file_location nvarchar(1000)
)
 
while (select top 1 * from #dbname) is not null
begin
 
    select @database = min(dbname) from #dbname
 
    set @cmd = 'use [' + @database + '];
		insert into ##filestats
			select @@servername as server_name, db_name() as [db_name], 
				case when f.type = 0 then ''data'' else ''log'' end as file_type,
				f.name as [file_name], 
				g.name as [group_name],
				cast(size / 128.0 as decimal(15,2)) as current_size_mb,  
				cast(fileproperty(f.name, ''spaceused'') as decimal(15,2)) as space_used_mb,
				cast(size / 128.0 - cast(fileproperty(f.name, ''spaceused'') as int) / 128.0 as decimal(15,2)) as free_space_mb,
				cast(100 * (1 - ((cast(fileproperty(f.name, ''spaceused'') as int) / 128.0) / (size / 128.0))) as decimal(15,2)) as percent_mb_free,
				f.physical_name as file_location 
			from sys.database_files as f
				left join sys.filegroups g on f.data_space_id = g.data_space_id
			where size > 0'
     
    if @drive is not null
		set @cmd = @cmd + ' where physical_name like ''' + @drive + ':\%'''
 
    exec sp_executesql @cmd
     
    delete from #dbname where dbname = @database
     
end
 
select *, (free_space_mb * 100 / current_size_mb) as percent_free
	from ##filestats
	order by [db_name], [file_name] --freespacemb desc
 
if (select object_id('tempdb.dbo.#dbname')) is not null
	drop table #dbname;

if (select object_id('tempdb.dbo.##filestats')) is not null
	drop table ##filestats;