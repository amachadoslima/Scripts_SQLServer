if(object_id(N'tempdb..#tempsessoes%') is not null)
	drop table #tempsessoes

select 
		s.session_id,
		c.client_net_address,
		s.[host_name],
		s.login_name,
		s.nt_user_name,
		s.login_time,
		s.[status],
		s.cpu_time,
		(s.memory_usage * 8) as 'memory_usage_kb', 
		db_name(st.[dbid]) as db, 
		st.[text],
		s.[program_name]
	into #tempsessoes
	from sys.dm_exec_sessions s
		left join sys.dm_exec_connections c on s.session_id = c.session_id
		left join sys.sysprocesses r on s.session_id = r.spid
		outer apply sys.dm_exec_sql_text (r.sql_handle) st
	where s.session_id > 50
		and	s.session_id <> @@spid 
	order by s.session_id 

declare @sessionid nvarchar(50)

declare sessionid cursor for 
	select session_id 
		from #tempsessoes

open sessionid
fetch next from sessionid into @sessionid

while(@@fetch_status = 0)
begin

	declare @cmd nvarchar(4000);
	set @cmd = 'dbcc inputbuffer(' + @sessionid + ')';

	print @cmd
	exec(@cmd)

    fetch next from sessionid into @sessionid
end

close sessionid
deallocate sessionid

if(object_id(N'tempdb..#tempsessoes%') is not null)
	drop table #tempsessoes