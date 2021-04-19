
set nocount on

declare @osql table
(
	spid			int,
	--pid			int,
	loginname		varchar(max),
	ultimaexecucao	datetime,
	sqltext			varchar(max),
	outputbuffer	varchar(max),
	killcmd			varchar(max)
)
	
declare @spid			nvarchar(50)
declare @pid			nvarchar(50)
declare @loginname		nvarchar(100)
declare @ultimaexecucao	datetime

begin try

	declare spid cursor for 
		select a.spid, a.loginame, a.last_batch, a.kpid
			from master..sysprocesses a
			where a.spid > 50 and a.spid <> @@spid and rtrim(ltrim(lower(a.status))) in('sleeping', 'dormant')
				

	open spid
	fetch next from spid into @spid, @loginname, @ultimaexecucao, @pid

		while(@@fetch_status = 0)
		begin
		
			insert into @osql (spid, ultimaexecucao, loginname)--, pid)
				select @spid, @ultimaexecucao, @loginname--, @pid
		
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
					outputbuffer = 'dbcc outputbuffer (' + @spid + ');',
					killcmd = 'kill ' + @spid + ';'
				where spid = @spid

			delete from @aux
			fetch next from spid into @spid, @loginname, @ultimaexecucao, @pid

		end

	close spid
	deallocate spid


	select * from @osql where sqltext is not null order by ultimaexecucao desc

end try
begin catch
	select error_line() as err_line, error_number() as err_num, error_message() as err_msg
	close spid
	deallocate spid
end catch