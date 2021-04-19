select
		b.resource_type,
		case
			when b.resource_type in ('database', 'file', 'metadata') then b.resource_type
			when b.resource_type = 'object' then object_name(b.resource_associated_entity_id)
			when b.resource_type in ('key', 'page', 'rid') then (
				select (
					case 
						when s.[name] collate latin1_general_ci_ai is not null then s.[name] collate latin1_general_ci_ai + '.' else '' end) + object_name(p.[object_id])
						from sys.partitions p
							join sys.objects o on o.[object_id] = p.[object_id]
							join sys.schemas s on o.[schema_id] = s.[schema_id]
						where p.hobt_id = b.resource_associated_entity_id) else 'unidentified' end as parent_object,
		b.request_mode as lock_type,
		b.request_status
	from sys.dm_os_waiting_tasks a
		join sys.dm_tran_locks b on b.lock_owner_address = a.resource_address
	where a.blocking_session_id is not null