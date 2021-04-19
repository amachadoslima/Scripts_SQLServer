select top 500
		[database_name],
		dateadd(hour, -3, start_time) as start_time,
		dateadd(hour, -3, end_time) as end_time,
		event_category,
		event_type,
		event_subtype_desc,
		severity 
		event_count,
		[description],
		additional_data
	from sys.event_log
	order by dateadd(hour, -3, end_time) desc