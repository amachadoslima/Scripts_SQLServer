select  
		convert(char(100), serverproperty('servername')) as [server], 
		b.[database_name],
		b.backup_start_date,
		b.backup_finish_date,
		datediff(second, b.backup_start_date, b.backup_finish_date) as [duration_seconds], 
		b.expiration_date, 
		case lower(b.[type])
			when 'd' then 'full backup'
			when 'i' then 'differential'
			when 'l' then 'log'
			when 'f' then 'file/filegroup'
			when 'g' then 'differential file'
			when 'p' then 'partial'
			when 'q' then 'differential partial'
			else 'unknown (' + b.[type] + ')' end as [backup_type], 
		cast(b.backup_size / 1024/ 1024 as decimal(10,2)) as backup_size_mb,
		cast(b.backup_size / 1024/ 1024/ 1024 as decimal(10,2)) as backup_size_gb,
		a.logical_device_name, 
		a.physical_device_name,   
		b.[name] as [backupset_name], 
		b.[description]
	from msdb.dbo.backupmediafamily as a  
		join msdb.dbo.backupset as b on a.media_set_id = b.media_set_id
	where (convert(datetime, b.backup_start_date, 102) >= getdate() - 20)  
		and b.[database_name] = 'Travessia_Guaruja1'
		and upper(b.[type]) = 'd'
	order by b.[database_name], b.backup_start_date asc