use SDBP12
go
select 
		s.[name] + '.' + t.[name] as tablename, 
		p.[rows] as [rows],
		cast((convert(decimal, sum(a.total_pages)) * 8 / 1024 /  1024) as decimal(10,5)) as totalgb, 
		cast((sum(a.used_pages)  * 8 / 1024 / 1024 ) as decimal(10,5)) as usedgb, 
		cast(((sum(a.total_pages) - sum(a.used_pages)) * 8 / 1024 / 1024 ) as decimal(10,5)) as unusedgb
	from sys.tables t
		join sys.indexes i on t.[object_id] = i.[object_id]
		join sys.partitions p on i.[object_id] = p.[object_id] and i.index_id = p.index_id
		join sys.allocation_units a on p.[partition_id] = a.container_id
		left outer join sys.schemas s on t.[schema_id] = s.[schema_id]
	where t.is_ms_shipped = 0
		and i.object_id > 255 
	group by t.[name], s.[name], p.[rows]
	order by usedgb desc, t.[name]