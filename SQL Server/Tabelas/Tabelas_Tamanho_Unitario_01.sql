use SDBP12
go

set transaction isolation level read uncommitted;

select 
		t.[name] as tablename, 
		p.[rows] as rowcounts,
		cast((convert(decimal, sum(a.total_pages)) * 8 / 1024) as decimal(10,2)) as total_mb, 
		cast((sum(a.used_pages)  * 8 / 1024) as decimal(10,2)) as used_mb, 
		cast(((sum(a.total_pages) - sum(a.used_pages)) * 8 / 1024) as decimal(10,2)) as unused_mb,
		cast((convert(decimal, sum(a.total_pages)) * 8 / 1024 / 1024) as decimal(10,2)) as total_gb, 
		cast((sum(a.used_pages)  * 8 / 1024 / 1024) as decimal(10,2)) as used_gb, 
		cast(((sum(a.total_pages) - sum(a.used_pages)) * 8 / 1024 / 1024) as decimal(10,2)) as unused_gb
	from sys.tables t
		join sys.indexes i on t.[object_id] = i.[object_id]
		join sys.partitions p on i.[object_id] = p.[object_id] and i.index_id = p.index_id
		join sys.allocation_units a on p.[partition_id] = a.container_id
		left outer join sys.schemas s on t.[schema_id] = s.[schema_id]
	where lower(t.[name]) = lower('SD2010_TTAT_LOG')
		and t.is_ms_shipped = 0
		and i.[object_id] > 255 
	group by t.[name], s.[name], p.[rows]
	order by total_gb desc, t.[name]