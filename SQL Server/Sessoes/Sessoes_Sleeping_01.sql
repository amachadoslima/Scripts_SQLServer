select 
		p.spid, 
		p.loginame, 
		p.[status], 
		p.memusage, 
		p.login_time, 
		p.last_batch,
		(datediff(hour, p.login_time, getdate())) as hours_sleeping, 
		p.hostname, 
		p.[program_name],
		db_name(st.[dbid]) as dbname, 
		st.[text],
		('kill ' + cast(p.spid as varchar) + ';') as kill_cmd, 
		('dbcc outputbuffer (' + cast(p.spid as varchar) + ')') as output_buffer
	from sys.sysprocesses p
		join sys.dm_exec_connections c on p.spid = c.session_id
		outer apply sys.dm_exec_sql_text (p.[sql_handle]) st
	where spid > 50
		and lower(p.[status]) = 'sleeping'
		and datediff(hour, p.last_batch, getdate()) >= 24
		and	p.spid <> @@spid
	order by p.memusage desc