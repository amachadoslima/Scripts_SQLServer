declare @current_tracefilename varchar(500)
declare @0_tracefilename varchar(500)
declare @indx int

select @current_tracefilename = [path]
	from sys.traces
	where is_default = 1

set @current_tracefilename = reverse(@current_tracefilename);
select @indx = patindex('%\%', @current_tracefilename);
set @current_tracefilename = reverse(@current_tracefilename);
set @0_tracefilename = left(@current_tracefilename, len(@current_tracefilename) - @indx) + '\log.trc';

select 
		DatabaseName, 
		te.[name], 
		[FileName], 
		convert(decimal(10, 3), Duration / 1000000e0) as time_taken_seconds, 
		StartTime, 
		EndTime, 
		(IntegerData * 8.0 / 1024) as changeinsize_mb, 
		ApplicationName, 
		HostName, 
		LoginName
	from ::fn_trace_gettable(@0_tracefilename, default) t
		join sys.trace_events as te on t.EventClass = te.trace_event_id
	where(trace_event_id >= 92
		and trace_event_id <= 95)
	order by t.StartTime desc