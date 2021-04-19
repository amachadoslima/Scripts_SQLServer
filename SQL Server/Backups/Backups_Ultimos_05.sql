use msdb
go

declare @qtd int = 0
declare @dbname varchar(max) = null
declare @sql nvarchar(max) = null
declare @type varchar(2) = null
declare @top int = 0

begin try


	set @sql = '
	select ' 

	if(isnull(@top, 0) > 0 )
		set @sql = @sql + ' 
		top (' + cast(@top as varchar) + ')'
		
	set @sql = @sql + '
			t1.[name],
			(dense_rank() over (order by backup_start_date desc,t3.backup_set_id)) % 2 as l1,
			(dense_rank() over (order by backup_start_date desc,t3.backup_set_id,t6.physical_device_name)) % 2 as l2,
			t3.[user_name],
			t3.backup_set_id,
			t3.[name] as backup_name,
			t3.[description],
			(datediff(ss, t3.backup_start_date, t3.backup_finish_date)) / 60.0 as duration,
			t3.backup_start_date,
			t3.backup_finish_date,
			case lower(t3.[type])
				when ''d'' then ''full backup''
				when ''i'' then ''differential''
				when ''l'' then ''log''
				when ''f'' then ''file/filegroup''
				when ''g'' then ''differential file''
				when ''p'' then ''partial''
				when ''q'' then ''differential partial''
				else ''unknown ('' + t3.[type] + '')'' end as [type],
			case when (t3.backup_size / 1024.0) < 1024 then (t3.backup_size / 1024.0) 
				when (t3.backup_size / 1048576.0) < 1024 then (t3.backup_size/1048576.0)
				else (t3.backup_size / 1048576.0/1024.0) end as backup_size,
			case when (t3.backup_size / 1024.0) < 1024 then ''kb''
				when (t3.backup_size / 1048576.0) < 1024 then ''mb''
				else ''gb'' end as backup_size_unit,       
			t3.first_lsn,       
			t3.last_lsn,       
			case when t3.differential_base_lsn is null then ''not applicable'' else convert(varchar(100), t3.differential_base_lsn)  end as [differential_base_lsn],
			t6.physical_device_name,       
			t6.device_type as [device_type],
			t3.recovery_model
	from sys.databases t1 with(nolock)
		join backupset t3 with(nolock) on (t3.[database_name] = t1.[name])
		left outer join backupmediaset t5 with(nolock) on (t3.media_set_id = t5.media_set_id)
		left outer join backupmediafamily t6 with(nolock) on (t6.media_set_id = t5.media_set_id)
	where t3.backup_start_date > case isnull(@qtd, 0) when 0 then cast(convert(varchar(10), getdate(), 121) + '' 00:00:00.000'' as datetime) else getdate() - @qtd end '

	if(isnull(@dbname, '') <> '')
	begin
		if(charindex(',', @dbname, 0) > 1)
		begin
			set @sql = @sql + ' and (t1.[name] in(''' + replace(@dbname, ',',''',''') + '''))'
		end
		else
			set @sql = @sql + ' and (t1.[name] = ''' + @dbname + ''')'
	end

	if(isnull(@type, '') <> '')
		set @sql = @sql + ' and (t3.[type] = ''' + @type + ''')'

	set @sql = @sql + char(10) + ' order by backup_start_date desc, t3.backup_set_id, t6.physical_device_name'

	print @sql 

	exec dbo.sp_executesql @sql, N'@qtd int', @qtd = @qtd 

end try
begin catch
	select error_number() as err_num, error_line() as err_row, error_message() as err_msg
end catch