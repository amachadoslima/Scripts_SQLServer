select
		wt.session_id,
		wt.exec_context_id as context_id,
		t.scheduler_id as schedulerid,
		case when wt.wait_duration_ms > 0 then (wt.wait_duration_ms / 1000) else null end as wait_seconds,
		wt.wait_type,
		wt.blocking_session_id as blk_id,
		wt.resource_description as [description],
		case wt.wait_type
			when N'cxpacket' then right (wt.resource_description, charindex (N'=', reverse(wt.resource_description)) - 1)
			else null end as node_id,
		s.[program_name],
		st.[text],
		r.database_id,
		db_name(r.database_id) as [db_name],
		qp.query_plan,
		r.cpu_time
	from sys.dm_os_waiting_tasks wt
		join sys.dm_os_tasks t on wt.waiting_task_address = t.task_address
		join sys.dm_exec_sessions s on wt.session_id = s.session_id
		join sys.dm_exec_requests r on s.session_id = r.session_id
		outer apply sys.dm_exec_sql_text (r.sql_handle) st
		outer apply sys.dm_exec_query_plan (r.plan_handle) qp
	where s.is_user_process = 1
	order by
		wt.session_id, wt.exec_context_id;