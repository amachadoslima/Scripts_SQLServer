USE msdb
GO
BEGIN

	SELECT DISTINCT 
			j.[name] AS NomeJob, 
			j.[enabled] AS Habilitado, 
    		sc.[name] AS NomeSchedule,
			CASE
				WHEN sc.freq_type = 1 THEN 'Uma vez'
				WHEN sc.freq_type = 4 THEN 'Diariamente'
				WHEN sc.freq_type = 8 THEN 'Semanalmente'
				WHEN sc.freq_type = 16 THEN 'Mensalmente'
				WHEN sc.freq_type = 32 THEN 'Mensalamente (relativo)'	
				WHEN sc.freq_type = 32 THEN 'Executar quando o SQL Server Agent iniciar'
			END AS FrequenciaExecucao,
			CASE
				WHEN sc.freq_subday_type = 1 THEN 'Em um horário específico' 
				WHEN sc.freq_subday_type = 2 THEN 'Segundos' 
				WHEN sc.freq_subday_type = 4 THEN 'Minutos' 
				WHEN sc.freq_subday_type = 8 THEN 'Horas' 
			END AS FrequenciaHorario,	
			Cast(Cast(sc.active_start_date AS VARCHAR(15)) AS DATETIME) AS DataInicializacao,	
			CASE 
				WHEN sc.active_end_date = '99991231' THEN NULL
				ELSE Cast(Cast(sc.active_end_date AS VARCHAR(15)) AS DATETIME) 
			END AS DataEncerramento,
			Stuff(Stuff(Right('000000' + Cast(js.next_run_time AS VARCHAR), 6), 3, 0, ':'), 6, 0, ':') AS HoraExecucao,	
			Convert(VARCHAR(24), sc.date_created, 121) as DataCriacao
		FROM sysjobs j
			JOIN sysJobschedules js ON j.job_id = js.job_id 
			JOIN sysSchedules sc on sc.Schedule_id=js.Schedule_id

END