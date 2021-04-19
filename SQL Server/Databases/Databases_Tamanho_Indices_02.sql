execute  master.sys.sp_MSforeachdb 
	'USE [?];

	select 
			getdate() as snap_date,
			serverproperty(''machinename'') as svr,
			@@servicename as sv, 
			''?'' [db_name], 
			nomtable = object_name(p.object_id),
			p.partition_id,
			p.partition_number,
			sum(case when (p.index_id < 2) and (a.type = 1) then p.rows else 0 end) as lignes,
			cast(ltrim(str(sum(a.total_pages) * 8192 / 1024.,15,0)) as float) as memory_kb,
			ltrim(str(sum(case
							when a.type <> 1 then a.used_pages
							when p.index_id < 2 then a.data_pages
							else 0
						end
					) * 8192 / 1024.,15,0)) as data_kb,
			ltrim(str((sum(a.used_pages) - sum(
						case
							when a.type <> 1 then a.used_pages
							when p.index_id < 2 then a.data_pages
							else 0
						end) )* 8192 / 1024.,15,0)) as indexes_kb, 
			p.data_compression,
			p.data_compression_desc
		from sys.partitions p, 
			sys.allocation_units a, 
			sys.sysobjects s
		where p.partition_id = a.container_id 
			and p.object_id = s.id 
			and s.type = ''U'' -- user table type (system tables exclusion)
		group by p.object_id, p.partition_id, p.partition_number, p.data_compression, p.data_compression_desc
		order by 3 desc' 
;