set nocount on

declare @osql table
(
	spid			int,
	[status]		varchar(max),
	db				varchar(100),
	--pid int,
	login_name		varchar(max),
	[host_name]		varchar(max),
	ini_exec		datetime,
	last_exec		datetime,
	sql_text		varchar(max),
	output_buffer	varchar(max),
	kill_cmd			varchar(max)
)
	
declare @db			nvarchar(100)
declare @spid		nvarchar(50)
declare @pid		nvarchar(50)
declare @hostname	nvarchar(100)
declare @loginname	nvarchar(100)
declare @iniexec	datetime
declare @lastexec	datetime
declare @status		varchar(100)

begin try

	declare spid cursor for 
		select s.session_id, db_name(r.database_id), s.login_name, r.start_time, s.last_request_end_time, s.host_process_id, upper(s.status), host_name
			from sys.dm_exec_sessions s
				left join sys.dm_exec_requests r on s.session_id = r.session_id
			where s.session_id > 50	and s.session_id <> @@spid
				

	open spid
	fetch next from spid into @spid, @db, @loginname, @iniexec, @lastexec, @pid, @status, @hostname

		while(@@fetch_status = 0)
		begin
		
			insert into @osql (spid, db, login_name, ini_exec, [status], last_exec, [host_name])--, pid)
				select @spid, @db, @loginname, @iniexec, upper(@status), @lastexec, case when isnull(@hostname, '') <> '' then @hostname else null end--, @pid
		
			declare @aux table
			(
				eventtype nvarchar(max),
				parameters nvarchar(max),
				eventinfo nvarchar(max)
			)
		
			insert into @aux
				exec ('dbcc inputbuffer(' + @spid + ') with no_infomsgs')
			
			update @osql
				set sql_text = (select rtrim(ltrim(replace(eventinfo, (char(13) + char(10)), ''))) from @aux),
					output_buffer = 'dbcc outputbuffer (' + @spid + ');',
					kill_cmd = 'kill ' + @spid + ';'
				where spid = @spid

			delete from @aux
			fetch next from spid into @spid, @db, @loginname, @iniexec, @lastexec, @pid, @status, @hostname

		end

	close spid
	deallocate spid


	select * from @osql where status <> 'DORMANT' order by status, last_exec desc

end try
begin catch
	select error_line() as err_line, error_number() as err_num, error_message() as err_msg
	close spid
	deallocate spid
end catch