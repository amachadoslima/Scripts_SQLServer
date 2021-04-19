use dersa_n3
go
begin

	select
			quotename(schema_name(t.[schema_id])) + '.' + quotename(t.[name]) as tbl_name,
			quotename(i.[name]) as idx_name,
			i.[type_desc],
			i.is_primary_key,
			i.is_unique,
			i.is_unique_constraint,
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
			cast((s.reserved_page_count * 8) / 1024. as decimal(12,2)) as tamanho_mb,
			cast((s.reserved_page_count * 8) / 1024. / 1024. as decimal(12,2)) as tamanho_gb,
			u.user_seeks,
			u.user_scans,
			u.user_lookups,
			u.user_updates,
			u.last_user_seek,
			u.last_user_scan,
			u.last_user_lookup, 
			u.last_user_update
	from sys.tables as t
		join sys.indexes as i on t.[object_id] = i.[object_id]
		left join sys.dm_db_index_usage_stats as u on i.[object_id] = u.[object_id] and i.index_id = u.index_id
		left outer join sys.dm_db_partition_stats s on i.[object_id] = s.[object_id] AND i.index_id = s.index_id
	where t.is_ms_shipped = 0
		and i.[type] <> 0
	order by tbl_name asc, idx_name asc

end