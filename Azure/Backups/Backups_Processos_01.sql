select
		r.session_id,
		r.database_id,
		r.command, 
		r.start_time,
		convert(int, r.percent_complete) as percente_complete,
		substring(st.[text], r.statement_start_offset / 2, case when r.statement_end_offset = -1 then 1000 else 
				(r.statement_end_offset - r.statement_start_offset) / 2 end) as sqlstatement
	from (select @@servername as [server]) s
		left join sys.dm_exec_requests r on lower(r.command) like '%backup%'
		outer apply sys.dm_exec_sql_text(r.[sql_handle]) st
	where  st.[text] not like '%COPY_ONLY%'