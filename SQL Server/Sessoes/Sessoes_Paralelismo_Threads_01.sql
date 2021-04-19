use master 
go
/*
	https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-os-waiting-tasks-transact-sql
*/
select 
		session_id,
		cpu_time,
		[status],
		wait_type,
		wait_time,
		total_elapsed_time, 
		(wait_time + cpu_time) as verify,
		datediff(ms, start_time, getdate()) as measured_elapsed_time,
		case when (wait_time + cpu_time) > datediff(ms, start_time, getdate()) then 'alert' else null end as msg
	from sys.dm_exec_requests 
	where session_id > 50 
		and session_id <> @@spid

select 
		t.session_id,
		t.task_state,
		t.exec_context_id,
		wt.wait_type,
		wt.wait_duration_ms,
		wt.resource_description
	from sys.dm_os_tasks t
		left join sys.dm_os_waiting_tasks wt on t.session_id = wt.session_id and t.exec_context_id = wt.exec_context_id
	where t.session_id > 50 
		and t.exec_context_id > 0
	order by session_id, t.exec_context_id