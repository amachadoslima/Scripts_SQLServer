select 
		db_name([dbid]) as [db_name],	
		count([dbid]) as num_conn, 
		loginame as login_name 
	from sys.sysprocesses 
	where dbid > 0 
	group by dbid, loginame
	order by num_conn desc