use SDBP12
go
select top 25 
		db_name(bd.database_id) as dbname,
		'[' + schema_name(sob.[schema_id]) + '].' + '[' + obj.[name] + ']' as [object_name],
		sob.[type_desc] as object_type,
		'[' + isnull(ix.[name], '---') + ']' as index_name,
		ix.[type_desc] as index_type,
		count_big(*) as buffered_page_count,
		count_big(*) * 8192 / (1024 * 1024) as buffer_mb,
		bd.page_type
	from  sys.dm_os_buffer_descriptors as bd
		join(
				select object_name([object_id]) as [name], index_id, allocation_unit_id, [object_id]
					from  sys.allocation_units as au
						join sys.partitions as p on au.container_id = p.hobt_id and (au.[type] = 1 or au.[type] = 3)
			union all
				select object_name([object_id]) as [name], index_id, allocation_unit_id, [object_id]
					from sys.allocation_units as au
						join sys.partitions as p on au.container_id = p.hobt_id and au.[type] = 2
		) as obj on bd.allocation_unit_id = obj.allocation_unit_id
		left join sys.indexes ix on	ix.[object_id] = obj.[object_id] and ix.index_id = obj.index_id
		left join sys.objects sob on ix.[object_id] = sob.[object_id]
	where  database_id = db_id()
		and sob.[type] not in('s','it')
	group by db_name(bd.database_id),
			'[' + schema_name(sob.[schema_id]) + '].' + '[' + obj.[name] + ']',
			obj.index_id,
			'[' + isnull(ix.[name], '---') + ']',
			ix.[type_desc],
			bd.page_type,
			sob.[type_desc]
	order by buffered_page_count desc