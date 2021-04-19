use SDBP12
go
select distinct 
		object_name(ix.[object_id]) as table_name, 
		x.[rows],
		cast(round(((sum(au.total_pages) * 8) / 1024.), 2) as numeric(36, 2)) as size_mb,
		cast(round(((sum(au.total_pages) * 8) / 1024. / 1024.), 2) as numeric(36, 2)) as size_gb,
		--left(right(df.physical_name, charindex('\', reverse(df.physical_name)) - 1), 
		--		charindex('.', right(df.physical_name, charindex('\', reverse(df.physical_name)) - 1)) - 1) as file_groupd_name, 
		--df.physical_name as data_file_name, 
		ds.[name] as file_group_name
	from sys.data_spaces ds
		join sys.database_files df on ds.data_space_id = df.data_space_id
		join sys.indexes ix on ix.data_space_id = ds.data_space_id and ix.index_id < 2
		join sys.objects o on ix.[object_id] = o.[object_id]
		join sys.partitions p on o.[object_id] = p.[object_id]
		join(
			select t.[object_id], sum(p.[rows]) as [rows]
				from sys.tables t
					join sys.partitions p on t.[object_id] = p.[object_id]
					join sys.indexes i on p.[object_id] = i.[object_id] and p.index_id = i.index_id
				where i.index_id < 2
				group by t.[object_id]
		) as x on o.[object_id] = x.[object_id]
		join sys.allocation_units au on p.[partition_id] = au.container_id
	where o.[type] = 'u'
		and o.is_ms_shipped = 0
		--and object_name(ix.[object_id]) = 'CTK010'
	group by ix.[object_id], x.[rows], df.physical_name, ds.[name]
	--order by file_groupd_name asc, size_mb desc
	order by file_group_name asc, size_mb desc