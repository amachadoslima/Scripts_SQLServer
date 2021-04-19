USE master 
GO
BEGIN

	declare @xp_cmdshell bit

	select @xp_cmdshell = isnull(cast([value] as bit), 0)
		from sys.configurations
		where lower([name]) = 'xp_cmdshell'

	if(@xp_cmdshell = 0)
	begin
		exec sp_configure 'show advanced options', 1;  reconfigure;
		exec sp_configure 'xp_cmdshell', 1;  reconfigure;
	end

	set nocount on
	set quoted_identifier off

	if(object_id(N'tempdb..##tmptraces') is not null)
		drop table ##tmptraces

	declare @id int 
	declare @file varchar(300)
	declare @folder varchar(300)
	declare @cmd varchar(400)
	declare @sql varchar(max)

	declare @arquivos table
	(
		trace varchar(4000)
	)

	select top 1 @id = id
		from sys.traces
		
	select @file = cast(value as varchar(300))
		from ::fn_trace_getinfo(@id)
		where property = 2
		
	select top (0) *
		into ##tmptraces
		from ::fn_trace_gettable(@file, default) 
		
		
	alter table ##tmptraces add CategoryID int
	alter table ##tmptraces add ErrorName varchar(300)
	alter table ##tmptraces add CategoryName varchar(300)
	

	insert into ##tmptraces
	select a.*, b.category_id, b.[name], c.[name]
		from ::fn_trace_gettable(@file, default) a
			join sys.trace_events b on b.trace_event_id = a.eventclass 
			join sys.trace_categories c on b.category_id = c.category_id
		where c.category_id in(3, 4)
		order by starttime asc
		
	select * 
		from ##tmptraces
		--where errorname like '%erro%'
		order by StartTime desc

	if(object_id(N'tempdb..##tmptraces') is not null)
		drop table ##tmptraces
	
	if(@xp_cmdshell = 0)
	begin
		exec sp_configure 'show advanced options', 1;  reconfigure;
		exec sp_configure 'xp_cmdshell', 0;  reconfigure;
	end

END