--informações sobre threads e uso dos processadores lógicos com o sql server
select  
		scheduler_id,
		cpu_id,
		[status],
		runnable_tasks_count,
		active_workers_count,
		load_factor,
		yield_count
	from sys.dm_os_schedulers
	where scheduler_id < 255
	
/*

	esta consulta tem total_worker_time como a medida da carga da cpu, e está em ordem decrescente do total_worker_time para 
	mostrar as consultas mais pesadas e seus planos no topo:

	observe as definições para essas duas colunas importantes:
	** total_worker_time: quantidade total de tempo de cpu, em microssegundos, que foi consumido pelas execuções 
						   deste plano desde que foi compilado.
						   
	** last_worker_time:  tempo de cpu, em microssegundos, que foi consumido na última vez que o plano foi executado.
*/
select top 10 
			st.[text],
			st.[dbid],
			st.objectid,
			qs.total_worker_time,
			qs.last_worker_time,
			qp.query_plan
	from sys.dm_exec_query_stats qs
		cross apply sys.dm_exec_sql_text(qs.[sql_handle]) st
		cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
	where qs.creation_time > convert(varchar(10), getdate(), 121) --referete ao dia corrent
	order by qs.total_worker_time desc 