select *
	from sys.dm_exec_requests r
		join sys.dm_exec_sessions s on r.session_id = s.session_id 
		join sys.dm_os_tasks t on r.task_address = t.task_address 
		join sys.dm_os_workers w on t.worker_address = w.worker_address 
		join sys.dm_os_threads th on w.thread_address = th.thread_address 
	where s.is_user_process = 1
		and s.session_id <> @@SPID