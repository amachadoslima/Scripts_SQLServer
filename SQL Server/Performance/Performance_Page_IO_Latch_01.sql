set nocount on

set dateformat ymd;

declare @osql table
(
	spid					int,
	[status]				varchar(100),
	db						varchar(100),
	wait_type				nvarchar(60),
	resource_description	nvarchar(3072),
	wait_duration_ms		bigint,
	login_name				varchar(max),
	[host_name]				varchar(max),
	ini_exec				datetime,
	sql_text				varchar(max),
	output_buffer			varchar(max),
	kill_cmd				varchar(max)
)
	
declare @db			nvarchar(100)
declare @waittype	nvarchar(60)
declare @resource	nvarchar(3072)
declare @waitdurms	bigint
declare @spid		nvarchar(50)
declare @pid		nvarchar(50)
declare @hostname	nvarchar(100)
declare @loginname	nvarchar(100)
declare @iniexec	datetime
declare @status		varchar(100)

begin try

	declare spid cursor for 
		select s.session_id, db_name(r.database_id), s.login_name, r.start_time, s.host_process_id, s.[status], [host_name], wt.wait_type, wt.resource_address, wt.wait_duration_ms
			from sys.dm_exec_sessions s
				join sys.dm_exec_requests r on s.session_id = r.session_id
				join sys.dm_os_waiting_tasks wt on wt.session_id = s.session_id
			where s.session_id > 50	
				and s.session_id <> @@spid
				and  wt.wait_type LIKE 'PAGEIOLATCH%'
	open spid
	fetch next from spid into @spid, @db, @loginname, @iniexec, @pid, @status, @hostname, @waittype, @resource, @waitdurms

		while(@@fetch_status = 0)
		begin
		
			insert into @osql (spid, db, login_name, ini_exec, [status], [host_name], wait_type, resource_description, wait_duration_ms)
				select @spid, @db, @loginname, @iniexec, @status, case when isnull(@hostname, '') <> '' then @hostname else null end, @waittype, @resource, @waitdurms
		
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
			fetch next from spid into @spid, @db, @loginname, @iniexec, @pid, @status, @hostname, @waittype, @resource, @waitdurms

		end

	close spid
	deallocate spid


	select * from @osql order by spid desc

end try
begin catch
	select error_line() as err_line, error_number() as err_num, error_message() as err_msg
	close spid
	deallocate spid
end catch