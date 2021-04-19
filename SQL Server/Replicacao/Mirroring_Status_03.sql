use msdb
go

set nocount on
set quoted_identifier off

if(object_id(N'tempdb..#dbmret') is not null)
	drop table #dbmret

create table #dbmret
(
	[db_name] varchar(255),
	[role] int,
	mirroring_state tinyint,
	witness_status tinyint,
	log_generate_rate int,
	unsent_log int,
	sent_rate int,
	unsretored_log int,
	recovery_rate int,
	transaction_delay int,
	transaction_per_sec int,
	average_delay int,
	time_recorded datetime,
	time_behind datetime,
	local_time datetime
)


/*
0 = �ltima linha
1 = linhas das �ltimas duas horas (padr�o do monitoramento)
2 = linhas das �ltimas quatro horas
3 = linhas das �ltimas oito horas
4 = linhas do �ltimo dia
5 = linhas dos �ltimos dois dias
6 = �ltimas 100 linhas
7 = �ltimo 500 linhas
8 = �ltimo 1.000 linhas
9 = �ltimas 1.000.000 linhas
*/
declare @rowsreturn int = 1
declare @db_name sysname = 'SDBP12'

insert into #dbmret
	exec sys.sp_dbmmonitorresults @db_name, @rowsreturn, 0 -- 0 = para n�o atualizar o status do db

select	[db_name],
		case [role] 
			when 1 then 'principal' 
			when 2 then 'espelhamento' 
			else 'n/a'
		end as [role],
		case mirroring_state
			when 0 then 'suspenso'
			when 1 then 'desconectado'
			when 2 then 'sincroniza��o'
			when 3 then 'failover pendente'
			when 4 then 'sincronizado' 
			else 'n/a'
		end as mirroring_state,
		case witness_status
			when 0 then 'desconhecido'
			when 1 then 'conectado'
			when 2 then 'desconectado'
			else 'n/a'
		end as witness_status,
		log_generate_rate,
		unsent_log,
		sent_rate,
		unsretored_log,
		recovery_rate,
		transaction_delay,
		transaction_per_sec,
		average_delay,
		time_recorded,
		time_behind,
		local_time 
	from #dbmret

if(object_id(N'tempdb..#dbmret') is not null)
	drop table #dbmret