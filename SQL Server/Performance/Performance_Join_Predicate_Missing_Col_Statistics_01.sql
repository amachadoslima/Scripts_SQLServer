use master 
go
-- missing join predicate and missing column statistics
select
		te.[name],
		t.DatabaseName,
		t.DatabaseID,
		t.NTDomainName,
		t.ApplicationName,
		j.[name] as JobName,
		t.LoginName,
		t.SPID,
		t.Duration,
		t.StartTime,
		t.EndTime,
		t.TextData
	from sys.fn_trace_gettable(convert(varchar(150),
		(
			select top 1 f.[value]
			from sys.fn_trace_getinfo(null) f
			where f.property = 2
		)), default) t
		join sys.trace_events te on	t.EventClass = te.trace_event_id
		cross apply(
			values (
				case 
					when rtrim(ApplicationName) like 'SQLAgent - TSQL JobStep (Job %' then
						cast(substring(rtrim(ApplicationName), 32, 8) + '-' + substring(rtrim(ApplicationName), 40, 4) + '-' + substring(rtrim(ApplicationName), 44, 4) + '-' +
						substring(rtrim(ApplicationName), 48, 4) + '-' +
						substring(rtrim(ApplicationName), 52, 12) as uniqueidentifier)
					else null end,
				case
					when rtrim(ApplicationName) like 'SQLAgent - TSQL JobStep (Job %' then cast(convert(varbinary(max),'0x' + substring(rtrim(ApplicationName), 32, 32),1) as uniqueidentifier)
					else null end)) val1(uqid, uqidstr)
		left join msdb..sysjobs j on j.job_id = val1.uqidstr
	where lower(te.name) in('missing column statistics', 'missing join predicate')
	order by t.StartTime

/*

a classe de evento missing column statistics indica que as estatísticas de coluna
que poderiam ter sido úteis para o otimizador não estão disponíveis.

para determinar se há estatísticas ausentes para uma coluna usada pela consulta, monitore a
classe de evento missing column statistics. isso pode fazer com que o otimizador escolha um 
plano de consulta menos eficiente do que seria esperado.


a classe de evento missing join predicate indica que uma consulta está sendo executada sem 
nenhum predicado de junção. isso pode resultar em uma consulta de longa execução.

*/