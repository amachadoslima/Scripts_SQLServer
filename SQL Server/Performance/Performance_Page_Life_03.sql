set transaction isolation level read uncommitted 
select 
		ple.[node] ,
		ltrim(str(pagelife_s / 3600)) + ':' + replace(str(pagelife_s % 3600 / 60,2), space(1), '0') + ':' + replace(str(pagelife_s % 60, 2), space(1), '0') as pagelife,
		ple.pagelife_s,
		dp.databasepages as bufferpool_pages,
		convert(decimal(15,3), dp.databasepages * 0.0078125) as bufferpool_mib ,
		convert(decimal(15,3), dp.databasepages * 0.0078125 / pagelife_s) as bufferpool_mib_s
	from 
	( 
		select instance_name as [node], cntr_value as pagelife_s
			from sys.dm_os_performance_counters 
			where lower([counter_name]) = 'page life expectancy' 
	) ple join 
	( 
		select instance_name as [node], cntr_value as databasepages
			from sys.dm_os_performance_counters 
			where lower(counter_name) = 'database pages' 
	) dp on ple.[node] = dp.[node]
	--where [pagelife_s] <= 300

/*
--exec master.dbo.sp_cleanupmemory
use master 
dbcc freeproccache;
dbcc dropcleanbuffers;
dbcc freesystemcache('all');
dbcc freesessioncache;
*/