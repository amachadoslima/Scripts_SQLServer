declare @cachedb decimal(10,6)
declare @memgb decimal(10,6)

;with cte as(
	select 
			db_name(database_id) as [dbname], 
			(count(*) * 8 / 1024.0) as [cached_size_mb]
		from sys.dm_os_buffer_descriptors
		where db_name(database_id) is not null
			and database_id > 4
		group by db_name(database_id)
		--order by [cached_size_mb] desc
)
select @cachedb = cast((cast(sum([cached_size_mb]) as decimal(10,2)) / 1024.) as decimal(10,6)) 
	from cte

select @memgb = cast((physical_memory_in_use_kb / 1024. / 1024.) as decimal(10,6)) 
	from sys.dm_os_process_memory with(nolock)

select 
	@memgb as mem_windows, 
	@cachedb as cachedb_sql, 
	(@memgb - @cachedb) as avaliable_mem