select
		a.session_id,
		s.login_name,
		a.transaction_id,
		d.[name],
		c.[name] as dbname,
		d.transaction_begin_time as dbtrantime, 
		a.is_local as [local],
		a.is_user_transaction as user_trans,
		('dbcc inputbuffer('  + rtrim(cast(a.session_id as varchar)) + ');') as input_buffer,
		('dbcc outputbuffer(' + rtrim(cast(a.session_id as varchar)) + ');') as output_buffer,
		('kill ' + rtrim(cast(a.session_id as varchar)) + ';') as kill_process
	from sys.dm_tran_session_transactions a
		join sys.dm_tran_database_transactions b on a.transaction_id = b.transaction_id
		join sys.databases c on b.database_id = c.database_id 
		join sys.dm_exec_sessions s on a.session_id = s.session_id
		left join sys.dm_tran_active_transactions d on a.transaction_id = d.transaction_id
	where lower(s.status) = 'sleeping'
		and datediff(second, d.transaction_begin_time, getdate()) >= 60
	order by a.session_id asc 