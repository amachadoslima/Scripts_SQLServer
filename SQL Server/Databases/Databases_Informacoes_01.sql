select
		[database_name] = ltrim(rtrim([name])),
		db_status = databasepropertyex([name], 'status'),
		db_owner = suser_sname(owner_sid),
		create_date,
		collation_name,
		[compatibility_level],
		[auto_close] = 
			case is_auto_close_on
				when 1 then 'on'
				when 0 then 'off'
				else null end,
		autocreate_statistics =
			case is_auto_create_stats_on	
				when 1 then 'on'
				when 0 then 'off'
				else null end,
		[auto_shrink] = 
			case is_auto_shrink_on	
				when 1 then 'on'
				when 0 then 'off' 
				else null end,
		autoupdate_statistics =
			case is_auto_update_stats_on
				when 1 then 'on'
				when 0 then 'off'
				else null end,
		auto_update_statistics_asynchronously =
			case is_auto_update_stats_async_on
				when 1 then 'on'
				when 0 then 'off'
				else null end,
		is_read_only =
			case is_read_only
				when 1 then 'read_only'
				when 0 then 'read_write'
				else null end,
		user_access_desc,
		recovery_model_desc
	from sys.databases 
	order by database_id desc