select 
		o.[name],
		ix.[name] as index_name,
		ix.index_id, 
		user_seeks + user_scans + user_lookups as reads,
		user_updates as writes ,
		(select sum(e.[rows]) from sys.partitions e where e.index_id = iu.index_id and iu.[object_id] = e.[object_id]) as [rows],
		case when iu.user_updates < 1 then 100 else 1.00 * (iu.user_seeks + iu.user_scans + iu.user_lookups) / iu.user_updates end as reads_per_write,
		'drop index ' + quotename(ix.[name]) + ' on ' + quotename(s.[name]) + '.' + quotename(object_name(iu.[object_id])) as drop_statement
	from sys.dm_db_index_usage_stats iu
		join sys.indexes ix on ix.index_id = iu.index_id and iu.[object_id] = ix.[object_id] 
		join sys.objects o on iu.[object_id] = o.[object_id]
		join sys.schemas s on o.[schema_id] = s.[schema_id]
	where objectproperty(iu.[object_id],'isusertable') = 1
		and iu.database_id = db_id() 
		and ix.[type_desc] = 'nonclustered'
		and ix.is_primary_key = 0
		and ix.is_unique_constraint = 0
		and (select sum(p.[rows]) from sys.partitions p where p.index_id = iu.index_id and iu.[object_id] = p.[object_id]) > 10000
	order by reads