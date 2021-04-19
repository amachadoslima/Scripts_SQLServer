use msdb 
go

set nocount on
declare @dias int = 0

select 
		a.[database_name],
		b.physical_device_name,
		convert(decimal(12,2), a.backup_size / 1024 / 1024) as size, 
		a.backup_start_date,
		a.backup_finish_date, cast(datediff(second, a.backup_start_date , a.backup_finish_date) as varchar(4)) as seconds_duration,
		case lower(a.[type]) when 'd' then 'full' when 'i' then 'differential' when 'l' then 'transaction log' end as backuptype, 
		a.server_name
	from msdb.dbo.backupset a
		join msdb.dbo.backupmediafamily b on a.media_set_id = b.media_set_id
	where a.[database_name] in (select [name] from sys.databases where [state] <> 6)
		and	a.backup_start_date > convert(char(10), (dateadd(day, - @dias, getdate())), 121)
	order by a.backup_start_date desc, a.backup_finish_date
