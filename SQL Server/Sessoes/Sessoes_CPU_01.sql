select
		r.session_id,
		r.cpu_time,
		st.text as [batch_text],
		substring(st.text, statement_start_offset / 2 + 1, (
			(
				case 
					when r.statement_start_offset = - 1
						then (len(convert(nvarchar(max), st.text)) * 2)
					else r.statement_end_offset
					end
				) - r.statement_start_offset
			) / 2 + 1) as [statement_text],
		qp.query_plan as [xml_plan],
		r.*
	from sys.dm_exec_requests r
		cross apply sys.dm_exec_sql_text(r.sql_handle) as st
		cross apply sys.dm_exec_query_plan(r.plan_handle) as qp
	where session_id <> @@spid
	order by r.cpu_time desc