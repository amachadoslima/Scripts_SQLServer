use dersa_n3
begin

	declare @idxName sysname = 'AK_TbSARTransacao_18'

	select
			db_name(database_id) as [db_name],
			'[' + object_schema_name(i.[object_id], database_id) + '].[' + object_name(i.[object_id]) + ']' as tbl_name,
			i.[name] as idx_name,
			u.user_seeks as pesquisas, 
			u.user_scans as varreduras, 
			u.user_lookups as lookups,
			u.last_user_seek as ultima_pesquisa, 
			u.last_user_scan as ultima_varredura,
			u.last_user_lookup as ultimo_lookup, 
			u.last_user_update as ultima_atualizacao
		from sys.indexes i
			left outer join sys.dm_db_index_usage_stats as u on i.[object_id] = u.[object_id] and i.index_id = u.index_id
		where database_id = db_id()
			and i.[name] = @idxName
end