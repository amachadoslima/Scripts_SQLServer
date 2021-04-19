use SDBP12
go
select	l.request_session_id as spid, 
		db_name(l.resource_database_id) as [db_name],
		schema_name(o.[schema_id]) + '.' + object_name(o.[object_id]) as locked_obj_name, 
		p.[object_id] as locked_obj_id, 
		l.resource_type as locked_resource,
		l.request_mode as lock_type,
		st.[text] as sql_statement_text,        
			case 
			when statement_start_offset = 0 and statement_end_offset = 0 then null
			else substring(st.[text], statement_end_offset / 2 + 1, 
				case when statement_end_offset = -1 then len(convert(nvarchar(max), st.[text]))
			else statement_end_offset / 2 - statement_start_offset / 2 + 1 end)
		end as off_set_text,
		es.login_name,
		es.[host_name],
		tst.is_user_transaction as is_user_transaction,
		at.[name] as transaction_name,
		cn.auth_scheme as authentication_method
	from sys.dm_tran_locks l
		join sys.partitions p on p.hobt_id = l.resource_associated_entity_id
		join sys.objects o on o.[object_id] = p.[object_id]
		join sys.dm_exec_sessions es on es.session_id = l.request_session_id
		join sys.dm_tran_session_transactions tst on es.session_id = tst.session_id
		join sys.dm_tran_active_transactions at on tst.transaction_id = at.transaction_id
		join sys.dm_exec_connections cn on cn.session_id = es.session_id
		cross apply sys.dm_exec_sql_text(cn.most_recent_sql_handle) as st
		join sys.dm_exec_requests r on es.session_id = r.session_id
	where resource_database_id = db_id()
	order by l.request_session_id