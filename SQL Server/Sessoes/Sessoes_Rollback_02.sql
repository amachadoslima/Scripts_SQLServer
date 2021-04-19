select
		session_id,
		command,
		[status],
		cast(percent_complete as decimal(10,2)) as [percent],
		start_time,
		dateadd(second, estimated_completion_time / 1000, getdate()) as [estimated_completion],*
	from sys.dm_exec_requests 
		where lower([status]) in ('killed/rollback','rollback') or command in ('killed/rollback','rollback')