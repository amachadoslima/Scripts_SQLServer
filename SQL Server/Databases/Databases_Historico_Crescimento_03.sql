declare @filename	nvarchar(1000)
declare @bc			int
declare @ec			int
declare @bfn		varchar(1000)
declare @efn		varchar(10)
		
 
select @filename = cast(value as nvarchar(1000))
	from ::fn_trace_getinfo(default)
	where traceid = 1 
		and property = 2;
 
set @filename = reverse(@filename);
set @bc = charindex('.', @filename);
set @ec = charindex('_', @filename)+1;
set @efn = reverse(substring(@filename, 1, @bc));
set @bfn = reverse(substring(@filename, @ec, len(@filename)));
set @filename = @bfn + @efn
 
select top 100 
		ftg.StartTime,
		te.[name] as event_name,
		db_name(ftg.DatabaseID) as [database_name],
		ftg.[FileName],
		(ftg.IntegerData * 8) / 1024.0 as [growth_mb],
		(ftg.Duration / 1000) as durms,
		ftg.ApplicationName,
		ftg.LoginName,
		ftg.TextData 
	from ::fn_trace_gettable(@filename, default) as ftg 
		inner join sys.trace_events as te on ftg.EventClass = te.trace_event_id
		where (ftg.EventClass = 92  -- date file auto-grow
			or ftg.EventClass = 93) -- log file auto-grow
		order by ftg.StartTime desc