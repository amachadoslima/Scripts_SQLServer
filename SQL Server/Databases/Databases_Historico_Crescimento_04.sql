use master 
go
declare @path nvarchar(1000)
declare @parm_dias int = 10

select @path = substring([path], 1, len([path]) - charindex(char(92), reverse([path]))) + '\log.trc'
	from sys.traces
	where id = 1

select 
		DatabaseName as [database_name],
		StartTime as [start_time],
		e.[name],
		count(*) as growthcount,
		LoginName as [login_name]
	from ::fn_trace_gettable(@path, 0)
		join sys.trace_events e on EventClass = trace_event_id
		join sys.trace_categories as cat on e.category_id = cat.category_id
	where cat.category_id = 2 
		and e.trace_event_id in(92,93)
		and StartTime >= dateadd(day, -@parm_dias, getutcdate())
	group by DatabaseName, StartTime, e.[name], LoginName
	order by [database_name], [start_time] desc