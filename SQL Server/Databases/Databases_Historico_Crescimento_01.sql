use SDBP12
go
-- log file auto grow/shrink 
select
		te.[name],
		t.DatabaseName,
		t.DatabaseID,
		t.NTDomainName,
		t.ApplicationName,
		t.LoginName,
		t.SPID,
		t.Duration,
		t.StartTime,
		t.EndTime
	from sys.fn_trace_gettable(convert(varchar(150),
		(
			select top 1 f.[value]
			from sys.fn_trace_getinfo(null) f
			where f.property = 2
		)), default) t
		join sys.trace_events te on	t.EventClass = te.trace_event_id
	where lower(te.[name]) = 'log file auto grow' or lower(te.[name]) = 'log file auto shrink'
	order by t.StartTime