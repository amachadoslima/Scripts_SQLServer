use master
go
-- hash/sort warnings
select
		te.[name] as [eventname],
		v.subclass_name,
		t.DatabaseName,
		t.DatabaseID,
		t.NTDomainName,
		t.ApplicationName,
		j.[name] as [jobname],
		t.LoginName,
		t.SPID,
		t.StartTime
	from sys.fn_trace_gettable(convert(varchar(150),
		(
			select top 1 f.[value]
			from sys.fn_trace_getinfo(null) f
			where f.property = 2
		)), default) t
		join sys.trace_events te on t.EventClass = te.trace_event_id
		join sys.trace_subclass_values v on	v.trace_event_id = te.trace_event_id and v.subclass_value = t.EventSubClass
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
	where lower(te.[name]) in('hash warning', 'sort warnings')
	order by StartTime desc
/*

hash warnings s�o recurs�es de hash ou esgotamento de hash durante uma opera��o de hashing.
o esgotamento hash ocorre quando uma opera��o de hashing atinge o n�vel m�ximo de 
recurs�o e � deslocada para um plano alternativo, de forma a processar os dados particionados restantes.
o esgotamento de hash geralmente ocorre devido a dados distorcidos.

- verificar estat�sticas

a classe de evento sort warnings indica as opera��es de classifica��o que n�o cabem na mem�ria. 
isso n�o inclui opera��es de classifica��o envolvendo a cria��o de �ndices, somente opera��es de 
classifica��o em uma consulta (como uma cl�usula order by usada em uma instru��o select).

*/