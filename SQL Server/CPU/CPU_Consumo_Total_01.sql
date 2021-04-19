--Obtém a porcentagem de uso de CPU em dois minutos, e a lerta se o consumo está acima dos 50%
GO

if(object_id('tempdb..#tempConsumoCPU') is not null) 
	drop table #tempconsumocpu;

create table #tempconsumocpu
(
    contador1 int,
    contador2 int
);

declare @i int = 1;

while(@i <= 6) -- insira o tempo de execução aqui! valor 6 = 1 minuto (6x10sec)
begin

    insert into #tempconsumocpu
		select cntr_value as contador1, (select cntr_value 
				from sys.dm_os_performance_counters with(nolock)
				where lower([object_name]) = 'sqlserver:resource pool stats' 
					and lower(counter_name) = 'cpu usage % base' 
					and lower(instance_name) = 'default') as contador2
		from sys.dm_os_performance_counters with(nolock)
		where lower([object_name]) = 'sqlserver:resource pool stats' 
			and lower(counter_name) ='cpu usage %' 
			and lower(instance_name) = 'default'

    waitfor delay '00:00:10' -- insira o valor de tempo para delay
    
	set @i = @i + 1

end

declare @cpu int
set @cpu = 50 -- insira o threshold para cpu

if(@cpu < (select avg(contador1) * 100 / avg(contador2) from #tempconsumocpu))
	select 'ALTO CONSUMO DE CPU!!!' as [status]
else 
	select 'Consumo normal de CPU' as [status]

select avg(contador1) * 100 / avg(contador2) [media cpu %] from #tempconsumocpu;

if(object_id('tempdb..#tempConsumoCPU') is not null) 
	drop table #tempconsumocpu;