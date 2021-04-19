create table #dbs
(
	[database_name]	varchar(50),
	[database_size]	float,
	[remarks]		varchar(100)
)
 
insert #dbs 
	exec ('exec sp_databases');
 
select 
		@@servername as server_name,
		[database_name],
		mfd.source_file_name_main,
		mfd.physical_name_data,
		mfl.source_file_name_log,
		mfl.physical_name_log,
		database_size as kb,
		round(database_size / 1024, 2) as mb,
		round((database_size / 1024) / 1024, 2) as gb,
		sdb.[compatibility_level],
		sdb.create_date,
		sdb.database_id,
		sdb.collation_name,
		sdb.recovery_model,
		sdb.recovery_model_desc,
		sdb.user_access,
		sdb.user_access_desc,
		sdb.[state],
		sdb.state_desc
	from #dbs as db
		join sys.databases as sdb on db.[database_name] = sdb.[name]
		join (
			select database_id, [name] as source_file_name_main, physical_name as physical_name_data
				from sys.master_files as sysmf
				where sysmf.file_id = 1
		) as mfd on mfd.database_id = sdb.database_id
		join (
			select database_id, [name] as source_file_name_log, physical_name as physical_name_log
				from sys.master_files as sysmf
				where sysmf.file_id = 2
		) as mfl on mfl.database_id = sdb.database_id
	where sdb.database_id > 4
	order by [database_name] asc
 
drop table #dbs;