set nocount on

if(object_id(N'tempdb..#tmpPLe') is not null)
	drop table #tmpPLe

declare @datacache decimal(10,5)
declare @cnrt decimal(10,5)
declare @value int

select 
		cast(count(*)*8/1024./1024. as decimal(10,5)) as [data_cache_size_gb], 
		case database_id when 32767 then 'resourcedb' else db_name(database_id) end as 'data_basename'
	into #tmpPLe
	from sys.dm_os_buffer_descriptors
	group by db_name(database_id) ,database_id
	order by [data_cache_size_gb] desc

select @cnrt = cast(cntr_value as decimal(10,5))
	from sys.dm_os_performance_counters
	where lower(object_name) like '%buffer manager%'
		and lower(counter_name) = 'page life expectancy'

select @datacache = sum([data_cache_size_gb]) from #tmpPLe
set @value = cast((@datacache / 4.) * 300 as int)

select
	case when @cnrt > @value then 'HIGH PAGE LIFE EXPECTANCY' 
		 when @cnrt <= @value then 'LOW PAGE LIFE EXPECTANCY' end as [Status], 
	cast(@cnrt as int) as cnrt_value, 
	@value as [value], 
	@datacache as data_cache

select * from #tmpPLe

if(object_id(N'tempdb..#tmpPLe') is not null)
	drop table #tmpPLe