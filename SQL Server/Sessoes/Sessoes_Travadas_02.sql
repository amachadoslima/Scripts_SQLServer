use master 
go

set nocount on

if(object_id(N'tempdb..#tmpInfo') is not null)
	drop table #tmpInfo

declare @i int = 0
declare @qtd int = 10

create table #tmpInfo
(
	id int identity(1,1),
	data_hora datetime,
	[object_name] nchar(256),
	counter_name nchar(256),
	instance_name nchar(256),
	cntr_value1 bigint,
	cntr_value2 bigint,
	avg_wait_time_ms bigint
)

while(@i <= @qtd)
begin

	if(object_id(N'tempdb..#tmpwt1') is not null)
		drop table #tmpwt1
	if(object_id(N'tempdb..#tmpwt2') is not null)
		drop table #tmpwt2
	
	begin try

		select *
			into #tmpwt1
			from sys.dm_os_performance_counters
			where counter_name = 'average wait time (ms)'
				and [object_name] = 'sqlserver:locks'
			
		waitfor delay '00:00:30'
	
		select *
			into #tmpwt2
			from sys.dm_os_performance_counters
			where counter_name = 'average wait time (ms)'
				and [object_name] = 'sqlserver:locks'
		
		insert into #tmpInfo(data_hora, [object_name], counter_name, instance_name, cntr_value1, cntr_value2, avg_wait_time_ms)
			select getdate(), a.[object_name], a.counter_name, a.instance_name, a.cntr_value as [cntr_value1], b.cntr_value as [cntr_value2], 
					((b.cntr_value - a.cntr_value) / 30) as avg_wait_time_ms
				from #tmpwt1 a
					join #tmpwt1 b on a.instance_name = b.instance_name
				where b.cntr_value > a.cntr_value

	end try
	begin catch
		select error_number() as err_num, error_message() as err_msg
	end catch
	
	if(object_id(N'tempdb..#tmpwt1') is not null)
		drop table #tmpwt1
	if(object_id(N'tempdb..#tmpwt2') is not null)
		drop table #tmpwt2

	set @i = @i + 1
end

select * 
	from #tmpInfo

if(object_id(N'tempdb..#tmpInfo') is not null)
		drop table #tmpInfo