select
		owt.session_id as spid,
		owt.blocking_session_id as block_spid,
		es.login_name,
		er.command,
		db_name(er.database_id) as [db_name],
		object_name(est.objectid) as obj_name,
		owt.exec_context_id as thread,
		ot.scheduler_id as scheduler,
		owt.wait_duration_ms as wait_ms,
		owt.wait_type,
		owt.resource_description,
		case owt.wait_type
			when N'cxpacket' then right (owt.resource_description, charindex (N'=', reverse(owt.resource_description)) - 1)
			else null
		end as node_id,
		eqmg.dop as dop,
		er.database_id as [dbid],
		eqp.query_plan,
		est.[text]
	from sys.dm_os_waiting_tasks owt
		join sys.dm_os_tasks ot on owt.waiting_task_address = ot.task_address
		join sys.dm_exec_sessions es on owt.session_id = es.session_id
		join sys.dm_exec_requests er on es.session_id = er.session_id
		full join sys.dm_exec_query_memory_grants eqmg on owt.session_id = eqmg.session_id
		outer apply sys.dm_exec_sql_text (er.[sql_handle]) est
		outer apply sys.dm_exec_query_plan (er.plan_handle) eqp
	where es.is_user_process = 1
	order by owt.session_id, owt.exec_context_id;