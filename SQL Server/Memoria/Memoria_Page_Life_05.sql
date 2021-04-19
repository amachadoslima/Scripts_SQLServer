-- https://medium.com/@pelegrini/indicadores-do-sql-server-page-life-expectancy-b82d0d0a377b

declare @cntrvalue bigint = null
declare @maxlimit bigint = null
declare @minlimit bigint = null
declare @maxmem bigint = null

select @cntrvalue = cast(cntr_value as bigint)
	from sys.dm_os_performance_counters
	where lower(object_name) like '%manager%' and lower(counter_name) = 'page life expectancy'
	
;with 
    tm_cte as (
        select (convert(int, value_in_use) / 1024.) as memory_gb, (convert(int, value_in_use) / 1024. / 4. * 300) as counter_by_memory
        from sys.configurations
        where lower([name]) like 'max server memory%'
    ),
    cached_cte as (select (count(*) * 8. / 1024. / 1024.) as cached_gb, (count(*) * 8. / 1024. / 1024.  / 4. * 300) as counter_by_cache
        from sys.dm_os_buffer_descriptors
)
select @maxlimit = cast(ceiling(counter_by_memory) as bigint), @minlimit = cast(ceiling(counter_by_cache)  as bigint), @maxmem = memory_gb
	from tm_cte, cached_cte;

select
	case when @cntrvalue > @maxlimit then 'High Page Life Expectancy (Max Value)'
		 when @cntrvalue > @minlimit  then 'High Page Life Expectancy (Min Value)'
		 when @maxlimit >= @cntrvalue then 'LOW PAGE LIFE EXPECTANCY'
		 when @minlimit >= @cntrvalue then 'LOW PAGE LIFE EXPECTANCY' end as [status],
	@cntrvalue as cntr_value, 
	@maxlimit as max_limit, 
	@minlimit as min_limit, 
	cast(@maxmem as varchar) + 'gb' as max_mem_server
	
--exec master.dbo.sp_cleanupmemory