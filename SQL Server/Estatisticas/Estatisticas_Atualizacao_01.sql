use SDBP12
go

if(object_id(N'tempdb..#tmpatualizaestatisticas') is not null)
	drop table #tmpatualizaestatisticas;

set nocount on

create table #tmpatualizaestatisticas
(
	id_estatistica	int identity(1,1),
	ds_comando		varchar(4000),
	nr_linha		int
)

;with tamanhotabelas as (
	select 
			o.[name],
			p.[rows]
		from sys.objects o
			join sys.indexes i on o.[object_id] = i.[object_id]
			join sys.partitions p on o.[object_id] = p.[object_id]
			join sys.allocation_units a	on a.container_id = p.[partition_id]
		where o.[type] = 'u' 
			and i.index_id in (0, 1) 
			and p.[rows] > 1000
		group by o.[name], p.[rows]
)

insert into #tmpatualizaestatisticas(ds_comando, nr_linha)
	select 'UPDATE STATISTICS [' + db_name() + '].[dbo].[' + o.[name] + ' ' + s.[name] + '] WITH FULLSCAN; ', t.[rows]
		from sys.stats s
			join sys.sysobjects o on s.[object_id] = o.id
			join sys.sysindexes i on i.id = o.id and s.[name] = i.[name]
			join tamanhotabelas t on o.[name] = t.[name]
		where  i.rowmodctr > 100
			and i.rowmodctr > t.[rows] * .005
			and substring(o.[name], 1, 3) not in('sys','dtp')
		order by t.[rows]

declare @loop int = 0
declare @comando nvarchar(4000)

while exists(select top 1 null from #tmpatualizaestatisticas)
begin

	if(getdate() > dateadd(mi, 50, dateadd(hh, 23, cast(floor(cast(getdate() as float)) as datetime))))-- hora > 23:50 am
	begin
		break-- sai do loop quando acabar a janela de manutenção
	end

	select @comando = ds_comando
		from #tmpatualizaestatisticas
		where id_estatistica = @loop

	--execute sp_executesql @comando
	print @comando

	delete from	#tmpatualizaestatisticas
		where id_estatistica = @loop

	set @loop= @loop + 1
end

if(object_id(N'tempdb..#tmpatualizaestatisticas') is not null)
	drop table #tmpatualizaestatisticas;

go