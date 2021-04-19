select 
		database_id,
		convert(varchar(1000), db.name) as dbname,
		state_desc,
		(select sum((size*8)/1024) from sys.master_files where db_name(database_id) = db.name and type_desc = 'rows') as [data mb],
		(select sum((size*8)/1024) from sys.master_files where db_name(database_id) = db.name and type_desc = 'log') as [log mb], 
		page_verify_option_desc as [page verify option], 
		recovery_model_desc as [recovery model], 
		-- last backup
		isnull((
			select top 1 
				case type when 'd' then 'full' when 'i' then 'differential' when 'l' then 'transaction log' end + ' – ' +
					ltrim(isnull(str(abs(datediff(day, getdate(),backup_finish_date))) + ' days ago', 'never')) + ' – ' +
					convert(varchar(20), backup_start_date, 103) + ' ' + convert(varchar(20), backup_start_date, 108) + ' – ' +
					convert(varchar(20), backup_finish_date, 103) + ' ' + convert(varchar(20), backup_finish_date, 108) +
					' (' + cast(datediff(second, bk.backup_start_date, bk.backup_finish_date) as varchar(4)) + ' '+ 'seconds)'
				from msdb..backupset bk where bk.database_name = db.name order by backup_set_id desc),'-') as [last backup],
		case when is_auto_close_on = 1 then 'autoclose' else null end as [autoclose],
		case when is_auto_shrink_on = 1 then 'autoshrink' else null end as [autoshrink],
		case when is_auto_create_stats_on = 1 then 'auto create statistics' else null end as [auto create statistics],
		case when is_auto_update_stats_on = 1 then 'auto update statistics' else null end as [auto update statistics],
		case compatibility_level
			when 60 then '60 (sql server 6.0)'
			when 65 then '65 (sql server 6.5)'
			when 70 then '70 (sql server 7.0)'
			when 80 then '80 (sql server 2000)'
			when 90 then '90 (sql server 2005)'
			when 100 then '100 (sql server 2008)'
			when 110 then '110 (sql server 2012)'
			when 120 then '120 (sql server 2014)'
			when 130 then '130 (sql server 2016)'
			when 140 then '140 (sql server 2017)'
		end as [compatibility level],
		user_access_desc as [user access],
		convert(varchar(20), create_date, 103) + ' ' + convert(varchar(20), create_date, 108) as [creation date],
		case when is_fulltext_enabled = 1 then 'fulltext enabled' else '' end as [fulltext]
	from sys.databases db
	order by [data mb] desc, dbname, [last backup] desc, name