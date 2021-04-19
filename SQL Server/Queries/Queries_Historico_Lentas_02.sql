select distinct top 15
		 substring(st.text, (s.statement_start_offset / 2) + 1,
			((case when s.statement_end_offset = -1
				then len(convert(nvarchar(max), st.text)) * 2
				else s.statement_end_offset
				end - s.statement_start_offset)/2) + 1) as 'individual_query',
		st.[text] as 'parent_query',
		s.execution_count,
		s.max_elapsed_time,
		isnull(s.total_elapsed_time / nullif(s.execution_count, 0), 0) as avg_elapsed_time,
		s.creation_time,
		isnull(s.execution_count / nullif(datediff(second, s.creation_time, getdate()),0), 0) as frequency_per_sec,
		s.last_logical_reads ,
		s.last_logical_writes,
		isnull(s.last_rows, 0) as last_rows,
		case st.[encrypted] when '0' then 'n' else 'y' end as [encrypted]
	from sys.dm_exec_query_stats s
		cross apply sys.dm_exec_sql_text(s.[sql_handle]) st
	order by s.max_elapsed_time desc	