use Dersa_N3
go
select 		
		schema_name(o.[schema_id]) + '.' + o.[name] as tbl_name, 
		i.[name] as idx_name, 
		i.index_id as idx_id,
		u.user_seeks as user_seek, 
		u.user_scans as user_scans,
		u.user_lookups as user_lookups, 
		u.user_updates as user_updates, 
		p.tablerows as table_rows,
		'drop index ' + quotename(i.[name]) + ' on ' + quotename(s.[name]) + '.'+ quotename(object_name(u.[object_id])) as drop_statement
	from sys.dm_db_index_usage_stats u
		join sys.indexes i on i.index_id = u.index_id and u.[object_id] = i.[object_id]
		join sys.objects o on u.[object_id] = o.[object_id]
		join sys.schemas s on o.[schema_id] = s.[schema_id]
		join (
			select sum(p.[rows]) tablerows, p.index_id, p.[object_id]
				from sys.partitions p 
			group by p.index_id, p.[object_id]) p on p.index_id = u.index_id and u.[object_id] = p.[object_id]
	where objectproperty(u.[object_id], 'isusertable') = 1
		and u.database_id = db_id()
		and lower(i.[type_desc]) = 'nonclustered'
		and i.is_primary_key = 0
		and i.is_unique_constraint = 0
	order by (u.user_seeks + u.user_scans + u.user_lookups) asc