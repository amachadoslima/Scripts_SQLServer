use master
go
create table #execrequests
(
	id						int identity(1,1) primary key,
	session_id				smallint not null,
	request_id				int,
	start_time				datetime,
	[status]				nvarchar(60),
	command					nvarchar(32),
	[sql_handle]				varbinary(64),
	statement_start_offset	int,
	statement_end_offset	int,
	[plan_handle]			varbinary(64),
	database_id				smallint,
	[user_id]				int,
	blocking_session_id		smallint,
	waittype				nvarchar(120),
	waittime				int,
	cputime					int,
	tot_time				int,
	reads					bigint,
	writes					bigint,
	logical_reads			bigint,
	[host_name]				nvarchar(256),
	[program_name]			nvarchar(256),
	blocking_these			varchar(1000) null
)

insert into #execrequests
(
	 session_id, request_id, start_time, [status], command, [sql_handle], statement_start_offset, statement_end_offset, [plan_handle],
	 database_id, [user_id], blocking_session_id, waittype, waittime, cputime, tot_time, reads, writes, logical_reads, [host_name], [program_name]
)
select 
		r.session_id, 
		request_id, 
		start_time, 
		r.[status], 
		command, 
		[sql_handle], 
		statement_start_offset, 
		statement_end_offset, 
		plan_handle, 
		r.database_id, 
		[user_id], 
		blocking_session_id, 
		wait_type, 
		wait_time, 
		r.cpu_time, 
		r.total_elapsed_time, 
		r.reads,
		r.writes, 
		r.logical_reads, 
		s.[host_name], 
		s.[program_name]
	from sys.dm_exec_requests r with(nolock)
		left outer join	sys.dm_exec_sessions s with(nolock) on r.session_id = s.session_id
	where 1 = 1
		and r.session_id > 50 -- apenas ids de usuários
		and r.session_id <> @@spid -- ignora a sessão que está executando esta query

update #execrequests 
	set	blocking_these = 
		(
			select isnull(convert(varchar(5), er.session_id), '') + ', '
				from #execrequests er
				where er.blocking_session_id = isnull(#execrequests.session_id, 0)
					and er.blocking_session_id <> 0
				for xml path('')
		)

select
		er.session_id, 
		er.[host_name], 
		er.[program_name], 
		er.[status], 
		er.blocking_these, 
		'len(blocking)' = len(er.blocking_these), 
		blockedby = er.blocking_session_id, er.tot_time, 
		db_name(er.database_id) as dbname, 
		er.command, er.waittype, 
		er.start_time, 
		er.tot_time, 
		er.waittime, 
		er.cputime, 
		er.reads, 
		er.writes, 
		er.logical_reads, 
		st.[text],  
		case 
			when er.statement_start_offset = 0 and er.statement_end_offset = 0 then null
			else substring(st.[text], er.statement_start_offset / 2 + 1, 
				case when er.statement_end_offset = -1 then len(convert(nvarchar(max), st.[text]))
			else er.statement_end_offset / 2 - er.statement_start_offset / 2 + 1 end)
		end as offsettext,
		er.statement_start_offset,
		er.statement_end_offset
	from #execrequests er with(nolock)
		outer apply sys.dm_exec_sql_text(er.[sql_handle]) st
	order by len(er.blocking_these) desc, er.session_id asc

drop table #execrequests
go