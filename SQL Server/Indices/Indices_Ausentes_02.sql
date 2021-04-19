use SDBP12
go
select  
		o.[name], 
		(avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) as impact,  
		'CREATE NONCLUSTERED INDEX IX_INDEXNAME ON ' + o.[name] collate database_default + ' ( ' + isnull(id.equality_columns, '') + 
			case when id.inequality_columns is null then '' 
				else case when id.equality_columns is null then '' 
				else ',' end + id.inequality_columns end + ' ) ' + 
					case when id.included_columns is null then '' else 'INCLUDE (' + id.included_columns + ')' end + ';' as create_index_statement, 
		id.equality_columns, 
		id.inequality_columns, 
		id.included_columns 
	from sys.dm_db_missing_index_group_stats as igs 
		join sys.dm_db_missing_index_groups as ig on igs.group_handle = ig.index_group_handle 
        join sys.dm_db_missing_index_details as id on ig.index_handle = id.index_handle and id.database_id = db_id() 
        join sys.objects o with(nolock) on id.[object_id] = o.[object_id] 
    where (igs.group_handle in( 
        select top (500) group_handle 
            from sys.dm_db_missing_index_group_stats with(nolock) 
            order by (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) desc))  
        and objectproperty(o.[object_id], 'isusertable')=1 
    order by 2 desc , 3 desc