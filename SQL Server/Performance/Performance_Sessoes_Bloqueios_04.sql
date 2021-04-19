select  
		object_name(p.[object_id]) as table_name, 
		resource_type, 
		resource_description
	from sys.dm_tran_locks l
		join sys.partitions p on l.resource_associated_entity_id = p.hobt_id