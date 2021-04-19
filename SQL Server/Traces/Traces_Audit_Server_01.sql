use master 
go
-- audit log
select
		te.[name] as [eventname],
		v.subclass_name,
		t.DatabaseName,
		t.DatabaseID,
		t.NTDomainName,
		t.ApplicationName,
		t.LoginName,
		t.SPID,
		t.StartTime,
		t.RoleName,
		t.SPID,
		t.TargetUserName,
		t.TargetLoginName,
		t.SessionLoginName
	from sys.fn_trace_gettable(convert(varchar(150),
		(
			select top 1 [value]
			from sys.fn_trace_getinfo(null) f
			where property = 2
		)), default) t
		join sys.trace_events te on t.EventClass = te.trace_event_id
		join sys.trace_subclass_values v on v.trace_event_id = te.trace_event_id and v.subclass_value = t.EventSubClass
	where lower(te.[name]) in('audit server starts and stops')