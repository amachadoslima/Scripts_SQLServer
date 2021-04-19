use master
go
select 
		cast(serverproperty('servername') as varchar(256)) as server_name,
		db.database_id,
		db.[name] as [db_name],
		id.[object_id],
		id.[statement] as fully_qualified_object_name,
		id.equality_columns,
		id.inequality_columns,
		id.included_columns,
		igs.unique_compiles,
		igs.user_seeks,
		igs.user_scans,
		igs.last_user_seek,
		igs.last_user_scan,
		igs.avg_total_user_cost,
		igs.avg_user_impact,
		igs.system_seeks,
		igs.system_scans,
		igs.last_system_seek,
		igs.last_system_scan,
		igs.avg_total_system_cost,
		igs.avg_system_impact,
		(igs.user_seeks * igs.avg_total_user_cost * (igs.avg_user_impact * 0.01)) as index_advantage,
		'CREATE INDEX [IX_' + object_name(id.object_id, db.database_id) + '_' + replace(replace(replace(isnull(id.equality_columns, ''), ', ', '_'), '[', ''), ']', '') 
				+ case when id.equality_columns is not null and id.inequality_columns is not null then '_' else '' end 
				+ replace(replace(replace(isnull(id.inequality_columns, ''), ', ', '_'), '[', ''), ']', '') + '_' 
				+ left(cast(newid() as nvarchar(64)), 5) + ']' + ' ON ' + id.statement + ' (' + isnull(id.equality_columns, '') 
				+ case when id.equality_columns is not null and id.inequality_columns is not null then ',' else '' end
				+ isnull(id.inequality_columns, '') + ')' + isnull(' INCLUDE (' + id.included_columns + ')', '') as proposed_index,
		cast(current_timestamp as smalldatetime) as collection_date
	from sys.dm_db_missing_index_group_stats igs with(nolock)
		join sys.dm_db_missing_index_groups ig with(nolock) on igs.group_handle = ig.index_group_handle
		join sys.dm_db_missing_index_details id with(nolock) on ig.index_handle = id.index_handle
		join sys.databases db with(nolock) on db.database_id = id.database_id
	where id.database_id > 4 -- remove this to see for entire instance
	order by index_advantage desc
	option (recompile);