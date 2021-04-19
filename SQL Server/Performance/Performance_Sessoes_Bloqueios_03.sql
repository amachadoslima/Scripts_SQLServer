use master 
go
select
		tl1.resource_type,
		db_name(tl1.resource_database_id) as [db_name],
		case tl1.resource_type
			when 'object' then object_name(tl1.resource_associated_entity_id, tl1.resource_database_id)
			when 'database' then 'db'
			else
				case 
					when tl1.resource_database_id = db_id() 
					then
						(
							select object_name(object_id, tl1.resource_database_id)
								from sys.partitions
								where hobt_id = tl1.resource_associated_entity_id
						)
					else '(run under db context)'
				end
		end as objectname,
		tl1.resource_description,
		tl1.request_session_id,
		tl1.request_mode,
		tl1.request_status,
		wt.wait_duration_ms as [wait duration (ms)],
		(
			select
				substring(
					s.text, 
					(er.statement_start_offset / 2) + 1,
					((
						case 
							er.statement_end_offset
						when -1 
							then datalength(s.text)
							else er.statement_end_offset
						end - er.statement_start_offset) / 2) + 1)		
			from 
				sys.dm_exec_requests er 
					cross apply sys.dm_exec_sql_text(er.sql_handle) s
			where
				tl1.request_session_id = er.session_id
		 ) as [query]
	from sys.dm_tran_locks as tl1 
		join sys.dm_tran_locks tl2 on tl1.resource_associated_entity_id = tl2.resource_associated_entity_id
		left outer join	sys.dm_os_waiting_tasks wt on tl1.lock_owner_address = wt.resource_address and tl1.request_status = 'wait'
	where tl1.request_status <> tl2.request_status 
		and(tl1.resource_description = tl2.resource_description or (tl1.resource_description is null and tl2.resource_description is null))
go