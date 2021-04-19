select 
		i.event_info as [sqltext],
		i.parameters,
		i.event_type,
		t.task_address, 
		t.parent_task_address,
		tsu.session_id,
		tsu.request_id,
		t.exec_context_id,
		tsu.user_objects_alloc_page_count/128 as total_usermb,
		(tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count)/128.0 as acive_usermb,
		tsu.internal_objects_alloc_page_count/128 as total_intmb,
		(tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count)/128.0 as active_intmb,
		t.task_state,
		t.scheduler_id,
		t.worker_address
	from sys.dm_db_task_space_usage tsu
		join sys.dm_os_tasks t on tsu.session_id = t.session_id and tsu.exec_context_id = t.exec_context_id
		outer apply sys.dm_exec_input_buffer(t.session_id, null) as i
	where t.session_id <> @@spid
	order by task_state, tsu.session_id