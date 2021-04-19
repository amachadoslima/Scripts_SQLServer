---- obtém valor atual (via performance monitor) do tempo médio de vida de uma página
--select * 
--	from sys.dm_os_performance_counters
--	where lower(object_name) like '%buffer manager%'
--		and lower(counter_name) = 'page life expectancy'


set nocount on

if(object_id(N'tempdb..#tmpMem') is not null)
	drop table #tmpMem
	
declare @memorymax bigint 
select @memorymax = cast(value_in_use as int) from sys.configurations WHERE name = 'max server memory (MB)'

select 
		@@servername as server_name, 
		[type], 
		(sum(single_pages_kb) / 1024.) as single_pages_mb, 
		(sum(multi_pages_kb) / 1024.) as multi_pages_mb, 
		@memorymax as memory_max
	into #tmpMem
	from sys.dm_os_memory_clerks
	group by [type]
	having sum(single_pages_kb) + sum(multi_pages_kb)  > 40000 -- só os maiores consumidores de memória
	order by sum(single_pages_kb) desc

select * 
	from #tmpMem
	where (single_pages_mb >= @memorymax or multi_pages_mb >= @memorymax)
	
select cast((sum(single_pages_kb)/1024.) as decimal(10,4)) as single_pages_mb, 
	   cast((sum(multi_pages_kb)/1024.) as decimal(10,4)) as multi_pages_mb
	from sys.dm_os_memory_clerks

if(object_id(N'tempdb..#tmpMem') is not null)
	drop table #tmpMem