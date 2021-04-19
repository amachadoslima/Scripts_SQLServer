use dersa_n3
go
begin
	
	select
			i.[name] as indexname,
			t.[name] as tablename,
			--sum(s.[used_page_count]) * 8 as indexsizekb
			cast((sum(s.[used_page_count]) * 8 / 1024.) as decimal(10,2)) as idx_size_mb,
			cast((sum(s.[used_page_count]) * 8 / 1024. / 1024. ) as decimal(10,2)) as idx_size_gb
		from sys.dm_db_partition_stats as s
			join sys.indexes as i on s.[object_id] = i.[object_id] and s.[index_id] = i.[index_id]
			join sys.tables t on t.[object_id] = i.[object_id]
		group by i.[name], t.[name]
		order by i.[name], t.[name]

end