use master 
go
begin

	set transaction isolation level read uncommitted
	set nocount on
	set quoted_identifier off

	;with bkps as
	(
		select
				[database_name] as [db_name],
				max(backup_finish_date) as last_backup_time,
				case lower([type]) 
					when 'd' then 'full' 
					when 'i' then 'differential' 
					when 'l' then 'log' end as [type]
			from msdb.dbo.backupset 
			where lower([type]) <> 'f'
			group by [database_name], [type]
	),
	bkpSize	as
	(
		select 
				rb.*, (select top 1 
								convert(decimal(10,4), bs.backup_size / 1024. / 1024. / 1024.) as backup_size 
							from msdb.dbo.backupset bs 
							where [db_name] = bs.[database_name]
								and last_backup_time = bs.backup_finish_date) as [backup_size]
			from bkps rb
	)
	select
			serverproperty('servername') as server_name,
			d.[name] as [db_name],
			d.state_desc as [state],
			d.recovery_model_desc as recovery_model, 
			------------ full ------------
			last_backup_time_full = case 
				when bf.last_backup_time is null then 'n/a'
				else convert(varchar(25), bf.last_backup_time, 121) end,
			last_full_days = case
				when datediff(day, bf.last_backup_time, getdate()) is null then 'n/a'
				else cast(datediff(day, bf.last_backup_time, getdate()) as varchar) end,
			full_bkp_size = case
				when replace(cast(bf.backup_size as varchar), '.', ',') is null then 'n/a'
				else replace(cast(bf.backup_size as varchar), '.', ',') end,
			------------ diff ------------
			--bd.last_backup_time as last_backup_time_diff,
			--datediff(day, bd.last_backup_time, getdate()) as last_diff_days,
			--bd.backup_size as diff_bkp_size,
			------------ log ------------
			--isnull(bl.last_backup_time, 'n/a') as last_backup_time_log,
			last_backup_time_log = case 
				when bl.last_backup_time is null then 'n/a'
				else convert(varchar(25), bl.last_backup_time, 121) end,
			last_log_min = case 
				when datediff(minute, bl.last_backup_time, getdate()) is null then 'n/a'
				else cast(datediff(minute, bl.last_backup_time, getdate()) as varchar) end,
			log_bkp_size = case
				when replace(cast(bl.backup_size as varchar), '.', ',') is null then 'n/a'
				else replace(cast(bl.backup_size as varchar), '.', ',') end
		from sys.databases d
			left join bkpSize bf on (d.[name] = bf.[db_name] and (bf.[type] = 'full' or bf.[type] is null))
			left join bkpSize bd on (d.[name] = bd.[db_name] and (bd.[type] = 'differential' or bd.[type] is null))
			left join bkpSize bl on (d.[name] = bl.[db_name] and (bl.[type] = 'log' or bl.[type] is null))
		where d.[name] <> 'tempdb'
		order by 5 desc

end