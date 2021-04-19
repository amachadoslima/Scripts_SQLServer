declare 
	 @dbname sysname
	,@days int

set @dbname = null 
set @days	= -90

select	
		h.destination_database_name as [database],
		h.[user_name] as [restored_by],
		case 
			when lower(h.restore_type) = 'd' then 'database'
			when lower(h.restore_type) = 'f' then 'file'
			when lower(h.restore_type) = 'g' then 'filegroup'
			when lower(h.restore_type) = 'i' then 'differential'
			when lower(h.restore_type) = 'l' then 'log'
			when lower(h.restore_type) = 'v' then 'verifyonly'
			when lower(h.restore_type) = 'r' then 'revert'
			else h.restore_type 
		end as [restore_type],
		h.restore_date as [restore started],
		m.physical_device_name as [restored_from],
		f.destination_phys_name as [restored_to]
	from msdb.dbo.restorehistory h
		join msdb.dbo.backupset s on h.backup_set_id = s.backup_set_id
		join msdb.dbo.restorefile f on h.restore_history_id = f.restore_history_id
		join msdb.dbo.backupmediafamily m on m.media_set_id = s.media_set_id
	where destination_database_name = isnull(@dbname, destination_database_name) 
		and	f.destination_phys_name like '%.mdf%'
		and h.restore_date >= dateadd(day, @days, getdate())
	order by h.restore_history_id desc
