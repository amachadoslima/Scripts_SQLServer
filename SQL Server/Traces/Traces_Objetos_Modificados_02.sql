use master 
go
begin

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

	if(object_id(N'tempdb..#tmpObjA') is not null)
		drop table #tmpObjA

	declare @fileName varchar(300)
	declare @folder varchar(200)
	declare @sql nvarchar(max)
	declare @cmd varchar(1000)

	select @fileName = cast(value as varchar(300))
		from ::fn_trace_getinfo(default)
			where traceid = 1
				and property = 2

	set @folder = reverse(substring(reverse(@fileName), charindex('\', reverse(@fileName)), 256))

	create table #tmpObjA
	(
		start_time datetime,
		[name] nvarchar(256),
		login_name nvarchar(512),
		nt_user_name nvarchar(512),
		[host_name] nvarchar(512),
		aplication_name nvarchar(512),
		spid int,
		[database_name] nvarchar(512),
		[schema_name] nvarchar(512),
		[object_name] nvarchar(512),
		[object_id] int
	)

	declare @files table
	(
		[file_name] varchar(500) 
	)

	set @cmd = N'dir "' + @folder + N'" /b | find /I ".trc"'

	insert into @files
		exec master..xp_cmdshell @cmd

	delete from @files where [file_name] is null

	declare curFiles cursor for
		select [file_name] 
			from @files 

	open curFiles
	fetch next from curFiles into @fileName

	while(@@fetch_status = 0)
	begin
		
		set @fileName = @folder + @fileName
		
		raiserror('Arquivo: "%s"', 0, 1, @fileName) with nowait;

		insert into #tmpObjA
		select
				StartTime,
				[name],
				LoginName,
				NTUserName,
				HostName,
				ApplicationName,
				SPID,
				DatabaseName,
				object_schema_name(ObjectID, DatabaseID),
				ObjectName,
				ObjectID
			from ::fn_trace_gettable(@fileName, default) as ftg 
				join sys.trace_events as te on ftg.EventClass = te.trace_event_id
			where ftg.EventClass = 164

		fetch next from curFiles into @fileName
	end
		
	close curFiles
	deallocate curFiles

	select distinct * 
		from #tmpObjA
		where [database_name] <> 'tempdb'
		order by start_time desc


	if(object_id(N'tempdb..#tmpObjA') is not null)
		drop table #tmpObjA

	if(@xp_cmdshell = 0)
	begin
		exec sp_configure 'show advanced options', 1;  reconfigure;
		exec sp_configure 'xp_cmdshell', 0;  reconfigure;
	end
end