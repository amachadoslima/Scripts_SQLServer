select	
		t.session_id, 
		w.pending_io_count, 
		st.[text], 
		is_preemptive,
		case w.wait_started_ms_ticks when 0 then 0 else (i.ms_ticks - w.wait_started_ms_ticks)/1000 end as suspended_wait,	 
		case w.wait_resumed_ms_ticks when 0 then 0 else (i.ms_ticks - w.wait_resumed_ms_ticks)/1000 end as runnable_wait,
		((i.ms_ticks - w.task_bound_ms_ticks) / 1000) as task_time, 
		((i.ms_ticks - w.worker_created_ms_ticks) / 1000) as worker_time,
		(w.end_quantum - w.start_quantum) as last_worker_quantum, 
		w.[state],
		w.last_wait_type,
		w.[affinity],
		w.quantum_used,
		w.tasks_processed_count
	from sys.dm_os_workers w
		join sys.dm_os_tasks t on w.task_address = t.task_address
		cross join sys.dm_os_sys_info i
		join sys.dm_exec_sessions s on s.session_id = t.session_id
		join sys.dm_exec_requests r on r.session_id = s.session_id
		outer apply sys.dm_exec_sql_text (r.[sql_handle]) st
	where t.session_id > 50 
		and t.session_id <> @@spid