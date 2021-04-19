use master 
go

set nocount on

declare @dteini datetime = getdate()
declare @maxsec int = 600

if(object_id(N'tempdb..#execrequests') is not null)
	drop table #execrequests

if(object_id(N'tempdb..##tmpreqbkl') is not null)
	drop table ##tmpreqbkl

while(datediff(second, @dteini, getdate()) <= @maxsec)
begin
	
	waitfor delay '00:00:01';

	create table #execrequests
	(
		id						int identity(1,1) primary key,
		sessionid				smallint not null,
		requestid				int,
		starttime				datetime,
		[status]				nvarchar(60),
		command					nvarchar(32),
		sqlhandle				varbinary(64),
		statementstartoffset	int,
		statementendoffset		int,
		planhandle				varbinary(64),
		databaseid				smallint,
		[userid]				int,
		blockingsessionid		smallint,
		waittype				nvarchar(120),
		waittime				int,
		cputime					int,
		tottime					int,
		reads					bigint,
		writes					bigint,
		logicalreads			bigint,
		hostname				nvarchar(256),
		programname				nvarchar(256),
		blockingthese			varchar(1000) null
	)

	insert into #execrequests(sessionid, requestid, starttime, [status], command, sqlhandle, statementstartoffset, statementendoffset, planhandle,
		 databaseid, userid, blockingsessionid, waittype, waittime, cputime, tottime, reads, writes, logicalreads, hostname, programname)
	select 
			r.session_id, request_id, start_time, r.[status], command, [sql_handle], statement_start_offset, statement_end_offset, 
			plan_handle, r.database_id, [user_id], blocking_session_id, wait_type, wait_time, r.cpu_time, r.total_elapsed_time, r.reads,
			r.writes, r.logical_reads, s.host_name, s.program_name
		from sys.dm_exec_requests r with(nolock)
			left outer join	sys.dm_exec_sessions s with(nolock) on r.session_id = s.session_id
		where 1 = 1
			and r.session_id > 50 -- apenas ids de usuários
			and r.session_id <> @@spid -- ignora a sessão que está executando esta query

	update #execrequests 
	set	blockingthese = 
	(
		select isnull(convert(varchar(5), er.sessionid), '') + ', '
			from #execrequests er
			where er.blockingsessionid = isnull(#execrequests.sessionid, 0)
			and er.blockingsessionid <> 0
		for xml path('')
	)

	if(object_id(N'tempdb..##tmpreqbkl') is null)
	begin
		select top(0)
			id = identity(int, 1,1), cast(null as varchar) as dte,
			cast(null as varchar) as sessionid, er.hostname, er.programname, er.[status], er.blockingthese, cast(null as varchar) as 'len(blocking)', cast(null as varchar) as blockedby,
			db_name(er.databaseid) as dbname, er.command, er.waittype, cast(null as varchar) as starttime, 
			cast(null as varchar) as tottime, cast(null as varchar) as waittime, 
			cast(null as varchar) as cputime, cast(null as varchar) as reads, cast(null as varchar) as writes, cast(null as varchar) as logicalreads, st.[text],  
			case 
				when er.statementstartoffset = 0 and er.statementendoffset = 0 then null
				else substring(st.[text], er.statementstartoffset / 2 + 1, 
					case when er.statementendoffset = -1 then len(convert(nvarchar(max), st.[text]))
				else er.statementendoffset / 2 - er.statementstartoffset / 2 + 1 end)
			end as offsettext,
			cast(null as varchar) as statementstartoffset,cast(null as varchar) as statementendoffset
		into ##tmpreqbkl
		from #execrequests er with(nolock)
			outer apply sys.dm_exec_sql_text(er.sqlhandle) st
	end

	insert into ##tmpreqbkl
		select convert(varchar(21), getdate(), 121), er.sessionid, er.hostname, er.programname, er.[status], er.blockingthese, 'len(blocking)' = len(er.blockingthese), 
				blockedby = er.blockingsessionid,
				db_name(er.databaseid) as dbname, er.command, er.waittype, convert(varchar(21), er.starttime, 121), 
				er.tottime, er.waittime, er.cputime, er.reads, er.writes, er.logicalreads, st.[text],  
				case 
					when er.statementstartoffset = 0 and er.statementendoffset = 0 then null
					else substring(st.[text], er.statementstartoffset / 2 + 1, 
				case when er.statementendoffset = -1 then len(convert(nvarchar(max), st.[text]))
					else er.statementendoffset / 2 - er.statementstartoffset / 2 + 1 end)
				end as offsettext,
				er.statementstartoffset,er.statementendoffset
			from #execrequests er with(nolock)
				outer apply sys.dm_exec_sql_text(er.sqlhandle) st
			where er.command not like '%BACKUP%'
			order by len(er.blockingthese) desc, er.sessionid asc

	if(@@rowcount > 0)
		-- skipping
		insert into ##tmpreqbkl
			select '------', '------', '------', '------', '------', '------', '------', '------', '------', '------', '------', 
				   '------', '------', '------', '------', '------', '------', '------', '------', '------','------','------'

	if(object_id(N'tempdb..#execrequests') is not null)
		drop table #execrequests

end

delete from ##tmpreqbkl where id = (select max(id) from ##tmpreqbkl where isnull(dte, '------') = '------')
select * from ##tmpreqbkl order by id

if(object_id(N'tempdb..##tmpreqbkl') is not null)
	drop table ##tmpreqbkl