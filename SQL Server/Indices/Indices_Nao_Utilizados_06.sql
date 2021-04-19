use dersa_n3
begin

	-- lista todos os índices
	;with idxs as
	(
		select
				db_name(database_id) as [db_name],
				'[' + object_schema_name(i.[object_id], database_id) + '].[' + object_name(i.[object_id]) + ']' as tbl_name,
				i.[name] as idx_name,
				i.[type_desc] as idx_type,
				stuff(replace(replace((
					select quotename(c.[name]) + case when ic.is_descending_key = 1 then ' desc' else '' end as [data()]
						from sys.index_columns as ic
							join sys.columns as c on ic.[object_id] = c.[object_id] and ic.column_id = c.column_id
						where ic.[object_id] = i.[object_id] and ic.index_id = i.index_id and ic.is_included_column = 0
						order by ic.key_ordinal
						for xml path), '<row>', ', '), '</row>', ''), 1, 2, '') as key_columns,
				stuff(replace(replace((
					select quotename(c.[name]) as [data()]
						from sys.index_columns as ic
							join sys.columns as c on ic.[object_id] = c.[object_id] and ic.column_id = c.column_id
						where ic.[object_id] = i.[object_id] and ic.index_id = i.index_id and ic.is_included_column = 1
						order by ic.index_column_id
						for xml path), '<row>', ', '), '</row>', ''), 1, 2, '') as included_columns,
				s.row_count as qtd_linhas,
				cast((s.reserved_page_count * 8) / 1024. as decimal(12,2)) as tamanho_mb,
				cast((s.reserved_page_count * 8) / 1024. / 1024. as decimal(12,2)) as tamanho_gb,
				u.user_seeks as pesquisas, 
				u.user_scans as varreduras, 
				u.user_lookups as lookups,
				u.last_user_seek as ultima_pesquisa, 
				u.last_user_scan as ultima_varredura,
				u.last_user_lookup as ultimo_lookup, 
				u.last_user_update as ultima_atualizacao,
				'drop index [' + i.[name] + '] on [' + object_schema_name(i.[object_id], database_id) + '].[' + (object_name(u.[object_id])) + ']' as drop_statement
			from sys.indexes i
				left outer join sys.dm_db_index_usage_stats as u on i.[object_id] = u.[object_id] and i.index_id = u.index_id
				left outer join sys.dm_db_partition_stats s on i.[object_id] = s.[object_id] AND i.index_id = s.index_id
			where database_id = db_id()
	)
	select
			[db_name],
			tbl_name,
			idx_name,
			idx_type,
			key_columns,
			included_columns,
			qtd_linhas,
			tamanho_mb,
			tamanho_gb,
			pesquisas,
			varreduras,
			lookups,
			ultima_pesquisa,
			ultima_varredura,
			ultimo_lookup,
			ultima_pesquisa,
			drop_statement
		from idxs 
		where (pesquisas + varreduras + lookups) = 0
		order by tamanho_mb desc 

end