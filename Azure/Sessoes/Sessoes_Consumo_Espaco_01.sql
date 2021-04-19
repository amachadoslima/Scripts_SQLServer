select	u.session_id,
		i.event_info as [sqltext],
		i.parameters,
		i.event_type,
		(u.user_objects_alloc_page_count / 128) as user_objs_total_sizemb,
		((u.user_objects_alloc_page_count - u.user_objects_dealloc_page_count) / 128.0) as user_objs_active_sizemb,
		(u.internal_objects_alloc_page_count / 128) as internal_objs_total_sizemb,
		((u.internal_objects_alloc_page_count - internal_objects_dealloc_page_count) / 128.0) as internal_objs_active_sizemb
	from sys.dm_db_session_space_usage u
		outer apply sys.dm_exec_input_buffer(u.session_id, null) as i
	where u.session_id <> @@spid
		and i.event_type <> 'No Event'
	order by user_objects_alloc_page_count desc