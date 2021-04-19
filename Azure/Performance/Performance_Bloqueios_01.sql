if(object_id(N'tempdb..#execrequests') is not null)
	drop table #execrequests;

create table #execrequests
(
	id						int identity(1,1) primary key,
	session_id				smallint not null,
	request_id				int,
	blocking_these			varchar(1000) null,
	start_time				datetime,
	[status]				nvarchar(60),
	command					nvarchar(32),
	[sql_handle]			varbinary(64),
	statement_start_offset	int,
	statement_end_offset	int,
	plan_handle				varbinary(64),
	databaseid				smallint,
	[userid]				int,
	blocking_session_id		smallint,
	wait_type				nvarchar(120),
	wait_time				int,
	cpu_time				int,
	tot_time				int,
	reads					bigint,
	writes					bigint,
	logical_reads			bigint,
	[host_name]				nvarchar(256),
	[program_name]			nvarchar(256)
)

insert into #execrequests
(
	 session_id, blocking_session_id, request_id, start_time, [status], command, [sql_handle], statement_start_offset, statement_end_offset, plan_handle,
	 databaseid, userid, wait_type, wait_time, cpu_time, tot_time, reads, writes, logical_reads, [host_name], [program_name]
)
select 
		r.session_id, 
		blocking_session_id, 
		request_id, start_time, 
		r.[status], 
		command, 
		[sql_handle], 
		statement_start_offset, 
		statement_end_offset, 
		plan_handle, 
		r.database_id, 
		[user_id], 
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
		and r.[status] <> 'background'

update #execrequests 
	set	blocking_these = 
		(
			select isnull(convert(varchar(5), er.session_id), '') + ', '
				from #execrequests er
				where er.blocking_session_id = isnull(#execrequests.session_id, 0)
					and er.blocking_session_id <> 0
				for xml path('')
		)

select * 
	from #execrequests 
	order by blocking_session_id, session_id;

if(object_id(N'tempdb..#execrequests') is not null)
	drop table #execrequests