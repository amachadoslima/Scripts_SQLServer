select 
		s.session_id as sessao,
		s.[host_name] as origem,
		r.last_wait_type as tipoespera,
		c.local_net_address as destino,
		c.last_read as ultima_leitura,
		c.last_write as ultima_escrita,
		t.[text],
		r.blocking_session_id as blocked_by
	from sys.dm_exec_connections c
		cross apply sys.dm_exec_sql_text(most_recent_sql_handle) as t
		join sys.dm_exec_sessions s on s.session_id = c.session_id
		join sys.dm_exec_requests r on s.session_id = r.session_id
	where s.session_id <> @@spid 
	order by c.last_read desc