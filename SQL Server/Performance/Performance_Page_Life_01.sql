declare @cntrvalue	bigint = null
declare @maxlimit	bigint = null
declare @minlimit	bigint = null
declare @maxmem		bigint = null
declare @disable	bit = 0
declare @clean		bit = 0

set nocount on

declare @ini datetime
set @ini = getdate()


if(object_id(N'tempdb..##tmpPLE') is null)
begin
	exec sp_executesql N'create table ##tmpPLE
		(
			[status]		varchar(800),
			cntrvalue		bigint,
			maxlimit		bigint,
			minlimit		bigint,
			maxmemserver	varchar(100),
			dte				datetime
		)'
end

if(object_id(N'tempdb..##tmpPLE') is not null)
begin
	if(@disable = 1)
	begin
		exec sp_executesql N'drop table ##tmpPLE'
		return
	end
	if(@clean = 1)
		exec sp_executesql N'delete from ##tmpPLE'
end

select @cntrvalue = cast(cntr_value as bigint)
	from sys.dm_os_performance_counters
	where lower(object_name) like '%manager%' and lower(counter_name) = 'page life expectancy'
	
;with tm_cte as(
		select(convert(int, value_in_use) / 1024.) as memory_gb, (convert(int, value_in_use) / 1024. / 4. * 300) as counter_by_memory
			from sys.configurations
			where lower(name) like 'max server memory%'
	),
	cached_cte as(
		select (count(*) * 8. / 1024. / 1024.) as cached_gb, (count(*) * 8. / 1024. / 1024.  / 4. * 300) as counter_by_cache
			from sys.dm_os_buffer_descriptors
)

select @maxlimit = cast(ceiling(counter_by_memory) as bigint), @minlimit = cast(ceiling(counter_by_cache)  as bigint), @maxmem = memory_gb
	from tm_cte, cached_cte;

exec sp_executesql N'
insert into ##tmpPLE
	select
		case when @cntrvalue > @maxlimit then ''High Page Life Expectancy (Max Value)''
				when @cntrvalue > @minlimit  then ''High Page Life Expectancy (Min Value)''
			when @maxlimit >= @cntrvalue then ''LOW PAGE LIFE EXPECTANCY''
			when @minlimit >= @cntrvalue then ''LOW PAGE LIFE EXPECTANCY''
		end as [status], @cntrvalue as cntrvalue, @maxlimit as maxlimit, @minlimit as minlimit, cast(@maxmem as varchar) + ''gb'' as maxmemserver, getdate() as dte',
		N'@cntrvalue bigint, @maxlimit bigint, @minlimit bigint, @maxmem bigint',
		@cntrvalue = @cntrvalue, @maxlimit = @maxlimit, @minlimit = @minlimit, @maxmem = @maxmem


exec sp_executesql N'select avg(cntrvalue) as average, count(*) as qtd from ##tmpPLE where dte >= dateadd(minute, -5, getdate()); 
					select * from ##tmpPLE where dte >= dateadd(minute, -5, getdate()) order by dte desc '
	
/*
--exec master.dbo.sp_cleanupmemory
use master 
go
dbcc freeproccache;
go
dbcc dropcleanbuffers;
go
dbcc freesystemcache('all');
go
dbcc freesessioncache;
*/