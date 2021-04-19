use dersa_n3
go
begin

	select 
			'[' + object_schema_name(i.[object_id], database_id) + '].[' + object_name(i.[object_id]) + ']' as table_name,
			coalesce(i.[name], space(0)) as index_name,
			--ps.partition_number,
			ps.row_count,
			cast((ps.reserved_page_count * 8) / 1024. as decimal(12,2)) as size_in_mb,
			cast((ps.reserved_page_count * 8) / 1024. / 1024. as decimal(12,2)) as size_in_gb,
			ius.user_seeks as pesquisas, 
			ius.user_scans as varreduras, 
			ius.user_lookups as lookups,
			ius.last_user_seek as ultima_pesquisa, 
			ius.last_user_scan as ultima_varredura,
			ius.last_user_lookup as ultimo_lookup, 
			ius.last_user_update as ultima_atualizacao,
			i.[type_desc]
		from sys.all_objects t
			join sys.indexes i on t.[object_id] = i.[object_id]
			join sys.dm_db_partition_stats ps on i.[object_id] = ps.[object_id] and i.index_id = ps.index_id
			left outer join sys.dm_db_index_usage_stats ius on ius.database_id = db_id() and i.[object_id] = ius.[object_id] and i.index_id = ius.index_id
		where database_id = db_id()
		order by table_name, i.[name]

end