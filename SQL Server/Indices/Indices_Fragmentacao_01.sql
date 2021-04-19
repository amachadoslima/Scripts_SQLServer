/*
	notas

	• avg_fragmentation_in_percent > 10% reduzir a fragmentação!
	• avg_page_space_used_in_percent < 75% reduzir a fragmentação!
	
	• avg_fragmentation_in_percent > 5% e < 30%, use o comando alter index reorganize
	• avg_fragmentation_in_percent > 30% use o alter index rebuild (substituto do dbcc dbreindex)
*/

select 
		db_name(db_id()) as [db_name], 
		'['+schema_name([schema_id]) +'].['+object_name(ps.[object_id])+']' as table_name,
		ps.index_type_desc, 
		ix.[name] as index_name, 
		ps.avg_fragmentation_in_percent, 
		ps.avg_page_space_used_in_percent,
		ps.record_count, 
		ps.avg_record_size_in_bytes
	from sys.dm_db_index_physical_stats(db_id(), null, null, null , 'sampled') ps
		join sys.tables tb on ps.[object_id] = tb.[object_id] 
		join sys.indexes ix on tb.[object_id] = ix.[object_id] and ps.index_id = ix.index_id
	where (ps.avg_fragmentation_in_percent > 10 or ps.avg_page_space_used_in_percent < 75.00)
		and index_type_desc <> 'HEAP'