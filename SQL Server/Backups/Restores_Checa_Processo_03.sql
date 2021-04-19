select
		d.[name],
		cast(percent_complete as decimal(10,3)) as [percent_complete],
		getdate() as [data_hora_atual],
		start_time as [data_hora_inicio],
		datediff(minute, start_time, getdate()) as [time_running],
		dateadd(second, estimated_completion_time / 1000, getdate()) as [datahora_estimado],
		command,
		b.[text]
	from sys.dm_exec_requests req
		join sys.sysdatabases d on d.[dbid] = req.database_id
		outer apply sys.dm_exec_sql_text(req.[sql_handle]) b
	where lower(req.command) like '%restore%'