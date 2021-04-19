select 
		session_id,
		[status], 
		cast(percent_complete as decimal(10,2)) as percentcomplete, 
		start_time, 
		dateadd(minute, (estimated_completion_time / 1000 / 60), getdate()) as [endtime],
		(estimated_completion_time / 1000 / 60) as [minrest], 
		(total_elapsed_time / 1000 / 60) as [minelapsed], 
		command, 
		wait_type, 
		last_wait_type
	from sys.dm_exec_requests
	where command like '%dbcc%'
	--where command = 'dbccfilescompact'