set nocount on

declare @osql table
(
	SPID			int,
	[Status]		varchar(100),
	HostName		varchar(100),
	IPAddrr			varchar(100),
	--programname		varchar(500),
	LoginName		varchar(100),
	ConnectTime		datetime,
	LastRequest		datetime,
	SQLText			varchar(max),
	Reads			int,
	Writes			int,
	LogicalReads	int,
	[RowCount]		int,
	--outputbuffer	varchar(max),
	KillCmd			varchar(max)
)
	
declare @spid			varchar(100)
declare @hostname		varchar(100)
declare @programname	varchar(500)
declare @loginname		varchar(100)
declare @connecttime	datetime
declare @lastrequest	datetime
declare @status			varchar(100)
declare @reads			int
declare @writes			int
declare @logicalreads	int
declare @rowcount		int
declare @ipaddrr		varchar(100)

begin try

	declare spid cursor for 
		select c.session_id, s.[host_name], s.login_name, dateadd(hour, -3, c.connect_time), dateadd(hour, -3, s.last_request_start_time), s.[status], 
				s.reads, s.writes, s.logical_reads, s.row_count, c.client_net_address
			from sys.dm_exec_connections as c with(nolock)
				join sys.dm_exec_sessions as s with(nolock) on c.session_id = s.session_id

	open spid
	fetch next from spid into @spid, @hostname, @loginname, @connecttime, @lastrequest, @status, @reads, @writes, @logicalreads, @rowcount, @ipaddrr

		while(@@fetch_status = 0)
		begin
		
			insert into @osql (spid, hostname, loginname, connecttime, lastrequest, [status], reads, writes, logicalreads, [rowcount], ipaddrr)
				select @spid, @hostname, @loginname, @connecttime, @lastrequest, @status, @reads, @writes, @logicalreads, @rowcount, @ipaddrr
		
			declare @aux table
			(
				eventtype nvarchar(max),
				parameters nvarchar(max),
				eventinfo nvarchar(max)
			)
		
			insert into @aux
				exec ('dbcc inputbuffer(' + @spid + ') with no_infomsgs')
			
			update @osql
				set sqltext = (select rtrim(ltrim(replace(eventinfo, (char(13) + char(10)), ''))) from @aux),
					--outputbuffer = 'dbcc outputbuffer (' + @spid + ');',
					killcmd = 'kill ' + @spid + ';'
				where spid = @spid

			delete from @aux
			fetch next from spid into @spid, @hostname, @loginname, @connecttime, @lastrequest, @status, @reads, @writes, @logicalreads, @rowcount, @ipaddrr

		end

	close spid
	deallocate spid


	select * 
		from @osql 
		where sqltext is not null 
			and loginname <> 'NT AUTHORITY\SYSTEM' 
			and spid <> @@spid 
			and [status] <> 'dormant'
			and [hostname] <> 'DETIC-PA300-5B'
		order by [status], spid

end try
begin catch
	select error_line() as err_line, error_number() as err_num, error_message() as err_msg
	close spid
	deallocate spid
end catch