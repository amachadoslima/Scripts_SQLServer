select
		st.session_id,
		s.login_name,
		st.transaction_id,
		ad.[name],
		db.[name] as [db_name],
		dt.database_transaction_begin_time as db_tran_time,
		ad.transaction_begin_time as tran_time, 
		(case dt.database_transaction_type
			when 1 then 'leitura/grava��o'
			when 2 then 'somente leitura'
			when 3 then 'sistema'
		end) as db_trans_type,
		(case dt.database_transaction_state
			when 1  then 'a transa��o n�o foi inicializada.'
			when 3  then 'a transa��o foi inicializada mas n�o gerou registros de log.'
			when 4  then 'a transa��o gerou registros de log.'
			when 5  then 'a transa��o foi preparada.'
			when 10 then 'a transa��o foi confirmada.'
			when 11 then 'a transa��o foi revertida.'
			when 12 then 'a transa��o est� sendo confirmada. neste estado est� sendo gerado o registro de log, mas ele n�o foi materializado nem persistiu.'
		end) as database_trans_state,
		dt.database_transaction_log_record_count as db_tran_log_count,
		st.is_local,
		st.is_user_transaction
	from sys.dm_tran_session_transactions st
		join sys.dm_tran_database_transactions dt on st.transaction_id = dt.transaction_id
		join sys.databases db on dt.database_id = db.database_id 
		join sys.dm_exec_sessions s on st.session_id = s.session_id
		left join sys.dm_tran_active_transactions ad on st.transaction_id = ad.transaction_id
	where (lower(db.log_reuse_wait_desc) = 'active_transaction' or dt.database_transaction_log_record_count > 0)
		and lower(s.[status]) <> 'sleeping'
	order by db_tran_log_count desc 