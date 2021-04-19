use dersa_n3
go
begin

	select 
			c.[name] as 'schema',
			b.[name] as 'tabela',
			d.[name] as 'index',
			a.avg_fragmentation_in_percent as pct_frag,
			a.page_count as 'paginas',
			case 
				when a.avg_fragmentation_in_percent > 5 and a.avg_fragmentation_in_percent < 30 then 'ALTER INDEX ' + d.[name] + ' ON ' + c.[name] + '.' + b.[name] + ' REORGANIZE' 
				when a.avg_fragmentation_in_percent >= 30 then 'ALTER INDEX ' + d.[name] + ' ON ' + c.[name] + '.' + b.[name]+' REBUILD' else null
			end comando
		from sys.dm_db_index_physical_stats (db_id(), null, null, null, null) as a
			join sys.tables b on b.[object_id] = a.[object_id]
			join sys.schemas c on b.[schema_id] = c.[schema_id]
			join sys.indexes as d on d.[object_id] = a.[object_id] and a.index_id = d.index_id
		where a.database_id = db_id()
			and a.avg_fragmentation_in_percent > 5
			and d.[name]  is not null
		order by a.avg_fragmentation_in_percent desc
end