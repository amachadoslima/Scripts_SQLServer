set nocount on
set transaction isolation level read uncommitted


	select 
			es.session_id as [session_id],
			coalesce(es.original_login_name, 'no info') as [login_name],
			coalesce(es.host_name,'no info') as [hostname],
			coalesce(es.last_request_end_time, es.last_request_start_time) as [last_batch],
			es.[status],
			coalesce(er.blocking_session_id, 0) as [blocked_by],
			coalesce(er.wait_type, 'miscellaneous') as [waittype],
			coalesce(er.wait_time, 0) as [waittime],
			coalesce(er.last_wait_type, 'miscellaneous') as [lastwaittype],
			coalesce(er.wait_resource, '') as waitresource,
			coalesce(db_name(er.database_id), 'no info') as [dbid],
			coalesce(er.command, 'awaiting command') as [cmd],
			sql_text = st.[text],
			transaction_isolation =
				case es.transaction_isolation_level
					when 0 then 'unspecified'
					when 1 then 'read uncommitted'
					when 2 then 'read committed'
					when 3 then 'repeatable'
					when 4 then 'serializable'
					when 5 then 'snapshot'
				end,
			coalesce(es.cpu_time, 0) + coalesce(er.cpu_time, 0) as [cpu],
			coalesce(es.reads, 0) + coalesce(es.writes, 0) + coalesce(er.reads, 0) + coalesce(er.writes, 0) as [physical_io],
			coalesce(er.open_transaction_count, -1) as [open_tran],
			coalesce(es.[program_name], '') as [program_name],
			es.login_time
		from sys.dm_exec_sessions es
			left outer join sys.dm_exec_connections ec on es.session_id = ec.session_id
			left outer join sys.dm_exec_requests er on es.session_id = er.session_id
			left outer join sys.server_principals sp on es.security_id = sp.sid
			left outer join sys.dm_os_tasks ota on es.session_id = ota.session_id
			left outer join sys.dm_os_threads oth on ota.worker_address = oth.worker_address
			cross apply sys.dm_exec_sql_text(er.sql_handle) as st
		where es.is_user_process = 1 
			and es.session_id <> @@spid

union 

	select 
		es.session_id as session_id,
		coalesce(es.original_login_name, 'no info') as login_name,
		coalesce(es.host_name, 'no info') as hostname,
		coalesce(es.last_request_end_time,es.last_request_start_time) as last_batch,
		es.[status],
		coalesce(er.blocking_session_id,0) as blocked_by,
		coalesce(er.wait_type,'miscellaneous') as waittype,
		coalesce(er.wait_time,0) as waittime,
		coalesce(er.last_wait_type,'miscellaneous') as lastwaittype,
		coalesce(er.wait_resource,'') as waitresource,
		coalesce(db_name(er.database_id),'no info') as [dbid],
		coalesce(er.command,'awaiting command') as cmd,
		sql_text = st.[text],
		transaction_isolation =
			case es.transaction_isolation_level
				when 0 then 'unspecified'
				when 1 then 'read uncommitted'
				when 2 then 'read committed'
				when 3 then 'repeatable'
				when 4 then 'serializable'
				when 5 then 'snapshot'
			end,
		coalesce(es.cpu_time,0) + coalesce(er.cpu_time,0) as cpu,
		coalesce(es.reads,0) + coalesce(es.writes,0) + coalesce(er.reads,0) + coalesce(er.writes,0) as physical_io,
		coalesce(er.open_transaction_count,-1) as open_tran,
		coalesce(es.[program_name],'') as [program_name],
		es.login_time
	from sys.dm_exec_sessions es
		inner join sys.dm_exec_requests ec2 on es.session_id = ec2.blocking_session_id
		left outer join sys.dm_exec_connections ec on es.session_id = ec.session_id
		left outer join sys.dm_exec_requests er on es.session_id = er.session_id
		left outer join sys.server_principals sp on es.security_id = sp.sid
		left outer join sys.dm_os_tasks ota on es.session_id = ota.session_id
		left outer join sys.dm_os_threads oth on ota.worker_address = oth.worker_address
		cross apply sys.dm_exec_sql_text(ec.most_recent_sql_handle) as st
	where es.is_user_process = 1 
	  and es.session_id <> @@spid