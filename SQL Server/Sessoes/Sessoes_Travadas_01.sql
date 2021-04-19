select
		b.request_session_id as [spid],
		a.name as [type],
		a.transaction_id as [transid],
		a.transaction_begin_time as [ini_time],
		case 
			when a.transaction_type = 1 then 'leitura/grava��o'
			when a.transaction_type= 2 then 'somente leitura'
			when a.transaction_type= 3 then 'sistema'
			when a.transaction_type = 4 then 'distribu�da' end as [trans_type],
		case 
			when a.transaction_state = 0 then 'n�o completamente inicializada'
			when a.transaction_state = 1 then 'inicializada mas n�o foi iniciada'
			when a.transaction_state = 2 then 'transa��o ativa'
			when a.transaction_state = 3 then 'a transa��o encerrada. leitura'
			when a.transaction_state = 4 then 'confirma��o iniciado na transa��o distribu�da'
			when a.transaction_state = 5 then 'estado preparado. aguardando resolu��o'
			when a.transaction_state = 6 then 'confirmada'
			when a.transaction_state = 7 then 'estado revertida'
			when a.transaction_state = 8 then 'revertida' end as [trans_state],
		case 
			when a.transaction_status = 1 then 'active'
			when a.transaction_status = 2 then 'prepared'
			when a.transaction_status = 3 then 'committed'
			when a.transaction_status = 4 then 'aborted'
			when a.transaction_status = 5 then 'recovered' end as [trans_status],
		b.resource_type,
		b.resource_subtype,
		db_name(b.resource_database_id) as dbname,
		b.resource_database_id as [dbid],
		b.resource_description as [description],
		b.resource_associated_entity_id as [entity_id],
		case 
			when b.resource_associated_entity_id between -2147483648 and 2147483647 then object_name(b.resource_associated_entity_id, b.resource_database_id)  
			else null end as [obj_name]
	from sys.dm_tran_active_transactions a
		join sys.dm_tran_locks b on a.transaction_id = b.request_owner_id
	order by b.request_session_id