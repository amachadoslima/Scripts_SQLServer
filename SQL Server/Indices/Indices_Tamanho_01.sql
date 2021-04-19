use dersa_n3
go
begin

	set transaction isolation level read uncommitted;

	with idx as
	(
		select 
				reserved_pages = (reserved_page_count),
				used_pages = (used_page_count),
				pages = (case when (s.index_id < 2) then (in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count) else lob_used_page_count + row_overflow_used_page_count end),
				s.[object_id],
				i.index_id,        
				i.[type_desc] as index_type,
				i.[name] as index_name
			from sys.dm_db_partition_stats s
				join sys.indexes i on s.[object_id] = i.[object_id] and s.index_id = i.index_id   
	)
	select distinct
			db_name(db_id()) as [db_name],
			o.[name] as tablename,
			o.[object_id],
			ct.index_name,
			ct.index_type,
			ct.index_id,
			indexspace = ltrim(str((case when used_pages > pages then case when ct.index_id < 2 then  pages else (used_pages - pages) end else 0 end) * 8, 15, 0) + ' kb')
		from idx ct
			join sys.objects o on o.[object_id] = ct.[object_id]
			join sys.dm_db_index_physical_stats (db_id(), null, null, null , null) ps on ps.[object_id] = o.[object_id] and ps.index_id = ct.index_id
		where ct.index_name = 'AK_TbSARTransacao_18'
		order by [name] asc

end