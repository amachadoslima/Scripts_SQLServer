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

	if(object_id(N'tempdb..#tmpLogin') is not null)
		drop table #tmpLogin

	declare @fileName varchar(300)
	declare @folder varchar(200)
	declare @sql nvarchar(max)
	declare @cmd varchar(1000)

	select @fileName = cast(value as varchar(300))
		from ::fn_trace_getinfo(default)
			where traceid = 1
				and property = 2

	set @folder = reverse(substring(reverse(@fileName), charindex('\', reverse(@fileName)), 256))

	create table #tmpLogin
	(
		start_time datetime,
		[name] nvarchar(256),
		[database_name] nvarchar(256),
		application_name nvarchar(512),
		login_name nvarchar(512),
		session_login_name nvarchar(512),
		text_data varchar(max),
		spid int,
		[host_name] nvarchar(512),
		error int
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

		insert into #tmpLogin
		select
				ftg.StartTime,
				te.[name],
				db_name(ftg.DatabaseID) as database_name,
				ftg.ApplicationName,
				ftg.LoginName,
				ftg.SessionLoginName,
				ftg.TextData,
				SPID,
				HostName,
				Error
			from ::fn_trace_gettable(@fileName, default) as ftg 
				join sys.trace_events as te on ftg.EventClass = te.trace_event_id
			where ftg.EventClass = 20

		fetch next from curFiles into @fileName
	end
		
	close curFiles
	deallocate curFiles

	select distinct * 
		from #tmpLogin
		order by start_time desc


	if(object_id(N'tempdb..#tmpLogin') is not null)
		drop table #tmpLogin

	if(@xp_cmdshell = 0)
	begin
		exec sp_configure 'show advanced options', 1;  reconfigure;
		exec sp_configure 'xp_cmdshell', 0;  reconfigure;
	end

end