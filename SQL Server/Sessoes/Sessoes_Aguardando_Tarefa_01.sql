select   
        l.resource_type,  
        l.resource_database_id,  
        l.resource_associated_entity_id,  
        l.request_mode,  
        l.request_session_id,  
        t.blocking_session_id  
	from sys.dm_tran_locks as l  
		join sys.dm_os_waiting_tasks t on l.lock_owner_address = t.resource_address;  