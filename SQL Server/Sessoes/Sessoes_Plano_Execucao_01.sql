select 
		b.login_name,
		b.[host_name],
		a.reads,
		a.writes,
		d.query_plan,
		c.database_transaction_log_record_count as qtd,
		case database_transaction_type
			when 1 then 'read/write'
			when 2 then 'read-only'
			when 3 then 'system' end as transtype, 
		case database_transaction_state
			when 1 then 'not been initialized'
			when 3 then 'initialized without log records'
			when 4 then 'generated log records'
			when 5 then 'begin tran'
			when 10 then 'commit tran'
			when 11 then 'rollback tran'
			when 12 then 'commit tran. the log record is being generated' end as transtate, *
	from sys.dm_exec_requests a
		join sys.dm_exec_sessions b on a.session_id = b.session_id
		left join sys.dm_tran_database_transactions c on a.transaction_id = c.transaction_id
		outer apply sys.dm_exec_query_plan (a.plan_handle) d
	where a.session_id > 50 and a.session_id <> @@spid