use SDBP12
go
-- server memory change
select 
		b.[name] as [event_name],
		c.subclass_name,
		a.IsSystem,
		a.StartTime,
		a.EndTime
	from sys.fn_trace_gettable(convert(varchar(150),
		(
			select top 1 a.[value]
				from sys.fn_trace_getinfo(null) a
				where a.property = 2
		)), default) a
		join sys.trace_events b on a.EventClass = b.trace_event_id
		join sys.trace_subclass_values c on c.trace_event_id = b.trace_event_id and c.subclass_value = a.EventSubClass
	where lower(b.[name]) in('server memory change')

/*

a classe de evento server memory change ocorre quando o uso de
memória do microsoft sql server aumenta ou diminui em 1 megabyte (mb) ou 5 por
cento da memória máxima de servidor, o que for maior.

*/