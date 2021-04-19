use master 
go
-- errorlog
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
		join sys.trace_events te on	t.eventclass = te.trace_event_id
	where lower(te.[name]) = 'errorlog'
	order by t.StartTime