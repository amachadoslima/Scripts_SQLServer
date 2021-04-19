declare @sql varchar(max) = null
declare @dias int = 0
declare @dbname sysname = null
declare @type varchar(1) = 'l'
declare @where bit = 0
declare @orderdte bit = 1

set @sql = '
select d.[name] as databasename, max(b.backup_finish_date) as lastbackuptime, 
		case lower(b.[type])
				when ''d'' then ''full backup''
				when ''i'' then ''differential''
				when ''l'' then ''log''
				when ''f'' then ''file/filegroup''
				when ''g'' then ''differential file''
				when ''p'' then ''partial''
				when ''q'' then ''differential partial''
				else ''unknown ('' + b.[type] + '')'' end as [type]
	from sys.sysdatabases d
		left outer join msdb.dbo.backupset b on b.database_name = d.[name] '

if(isnull(@dbname, '') <> '')
begin
	set @sql = @sql + '
	where lower(d.[name]) = ''' + lower(@dbname) + ''''
	set @where = 1
end

if(@type is not null)
begin
	if(@where = 1)
		set @sql = @sql + ' 
		and lower(b.[type]) = ''' + lower(@type) + ''''
	else
	begin
		set @sql = @sql + ' 
	where lower(b.[type]) = ''' + lower(@type) + ''''
		set @where = 1
	end
end

if(@dias is not null)
begin
	if(@where = 1)
		set @sql = @sql + ' 
		and b.backup_finish_date >= dateadd(day, -' + cast(@dias as varchar) + ', cast(getdate() as date))'
	else 
		set @sql = @sql + ' 
	where b.backup_finish_date >= dateadd(day, -' + cast(@dias as varchar) + ', cast(getdate() as date))'
end

set @sql = @sql + '
	group by d.[name], b.[type] '

if(isnull(@orderdte, 0) = 0)
	set @sql = @sql + ' 
	order by d.[name] '
else 
	set @sql = @sql + ' 
	order by 2 desc '

print @sql

exec (@sql)