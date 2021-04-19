USE master 
BEGIN

	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF

	DECLARE @Path VARCHAR(300) = 'MeuTrace'
	DECLARE @TraceID INT = 1
	DECLARE @Resultados TABLE
	(
		IDLinha INT IDENTITY(1,1),
		LinhaComando VARCHAR(MAX)
	)
	
	If(NOT EXISTS(SELECT 1 FROM sys.traces WHERE id = @TraceID))
	Begin
		RAISERROR('* Trace (ID = %i) não encontrado! Chece a sys.traces para mais detalhes.', 0, 1, @TraceID) WITH NOWAIT;
		RETURN
	End

	INSERT INTO @Resultados(LinhaComando) 
		SELECT '--Declaração de variáveis para parametrização do TRACE ' UNION ALL
		SELECT 'DECLARE @TraceIDOut       INT           ' UNION ALL
		SELECT 'DECLARE @Options          INT           ' UNION ALL
		SELECT 'DECLARE @Path             NVARCHAR(256) ' UNION ALL 
		SELECT 'DECLARE @Maxfilesize      BIGINT        ' UNION ALL
		SELECT 'DECLARE @MaxRolloverFiles INT           ' UNION ALL
		SELECT 'DECLARE @StopTime         DATETIME      ' UNION ALL
		SELECT 'DECLARE @On               BIT           ' UNION ALL
		SELECT '                                        ' UNION ALL
		SELECT 'Set @On = 1 -- Para fins de script, acho melhor sempre definir um script para iniciar o rastreamento após a criação. '

	-- Script das configurações da sys.traces
	INSERT INTO @Resultados(LinhaComando) 
		SELECT 'set @maxfilesize = ' + CASE WHEN max_size IS NULL THEN '20' ELSE CONVERT(varchar,max_size) END + ' --size in MB ' from sys.traces WHERE id =@TraceID
	
	INSERT INTO @Resultados(LinhaComando) 
		SELECT 'Set @MaxRolloverFiles = ' + CASE WHEN max_files IS NULL THEN ' 5 ' ELSE CONVERT(VARCHAR, max_files) END + 
			'  --Número de arquivos; ou seja, com 5 arquivos, ele sobrescreve os arquivos anteriores ' from sys.traces WHERE id =@TraceID

	INSERT INTO @Resultados(LinhaComando) 
		SELECT 'Set @Stoptime = ' + CASE WHEN stop_time IS NULL THEN 'NULL' ELSE '''' + 
			CONVERT(VARCHAR(40), stop_time, 121)+ '''' END + '  -- NULL significa que não há fim, caso contrário, especifique uma data ' FROM sys.traces WHERE id = @TraceID

	INSERT INTO @Resultados(LinhaComando) 
		SELECT 'Set @Options = 2' -- Sobrescreva, ignore todas as opções anteriores
	
	INSERT INTO @Resultados(LinhaComando) 
		SELECT  'Set @Path  = '''  + CASE WHEN [path] IS NULL THEN @Path ELSE Left([path], Len([path]) - 4) END + '''' + 
				'  -- O trace adiciona ".trc" ao nome completo do arquivo, por isso evite "name.trc.trc", remova-o do teu script ' FROM sys.traces WHERE id = @TraceID
	
	INSERT INTO @Resultados(LinhaComando) 
		SELECT '' 
	
	/*
		DOC:
		sp_trace_create [ @TraceID = ] trace_id OUTPUT 
			, [ @options = ] option_value 
			, [ @tracefile = ] 'trace_file' 
			[ , [ @maxfilesize = ] max_file_size ]
			[ , [ @stoptime = ] 'stop_time' ]
			[ , [ @filecount = ] 'max_rollover_files' ]
	*/

	INSERT INTO @Resultados(LinhaComando) 
		SELECT '  --Cria o trace... '   

	INSERT INTO @Resultados(LinhaComando) 
		SELECT '--Cria o trace ' UNION ALL
		SELECT 'EXEC sp_trace_create ' UNION ALL
		SELECT '    @TraceID           = @TraceIDOut OUTPUT, ' UNION ALL
		SELECT '    @options           = @Options, ' UNION ALL
		SELECT '    @tracefile         = @Path, ' UNION ALL
		SELECT '    @maxfilesize       = @Maxfilesize, ' UNION ALL
		SELECT '    @stoptime          = @StopTime, ' UNION ALL
		SELECT '    @filecount         = @MaxRolloverFiles ' 

	--Detalhes
	INSERT INTO @Resultados(LinhaComando) 
		SELECT ''

	INSERT INTO @Resultados(LinhaComando) 
		SELECT  '  --Para o evento de todas instruções SQL concluídas, capture colunas de dados acessíveis  ' 
			--EXEMPLO: exec sp_trace_setevent @TraceIDout, 12, 6, @on --SQL:BatchCompleted,NTUserName    

	INSERT INTO @Resultados(LinhaComando) 
		SELECT 
				'  EXEC sp_trace_setevent @TraceIDout,' + CONVERT(VARCHAR(MAX), X.eventid) + ',' +  CONVERT(VARCHAR(MAX),X.columnid) + ',@On -- ' +  E.[Name] + ',' + V.[name]
			FROM  ::fn_trace_geteventinfo(@TraceID) AS X
				JOIN sys.trace_events E ON X.eventid  = E.trace_event_id
				JOIN sys.trace_columns V ON X.columnid = V.trace_column_id

	INSERT INTO @Resultados(LinhaComando) 
		SELECT '--Filtros'

	INSERT INTO @Resultados(LinhaComando) 
		SELECT ''

	INSERT INTO @Resultados(LinhaComando) 
		SELECT 
				'  EXEC sp_trace_setfilter  traceidout' + ',' + CONVERT(VARCHAR, X.columnid) + 
				',' + CONVERT(VARCHAR, logical_operator) + 
				',' + CONVERT(VARCHAR, comparison_operator) + ',' +  
				' N''' + CONVERT(VARCHAR(8000), [value]) + ''' ' + 
				'  -- ' + CASE WHEN logical_operator = 0 THEN ' AND ' ELSE ' OR ' END + V.[name] + 
				CASE 
					WHEN comparison_operator = 0  THEN ' = '
					WHEN comparison_operator = 1  THEN ' <> '
					WHEN comparison_operator = 2  THEN '  > '
					WHEN comparison_operator = 3  THEN '  <  '
					WHEN comparison_operator = 4  THEN '  >=  '
					WHEN comparison_operator = 5  THEN ' <=  '
					WHEN comparison_operator = 6  THEN '  LIKE  '
					WHEN comparison_operator = 7  THEN ' NOT LIKE  '
				END + CONVERT(VARCHAR(8000), [value]) 
		FROM ::fn_trace_getfilterinfo(@TraceID) X 
			JOIN sys.trace_columns V ON X.columnid = V.trace_column_id

	INSERT INTO @Resultados(LinhaComando) 
		SELECT '---Passo final'
	
	INSERT INTO @Resultados(LinhaComando) 
		SELECT ''
	
	INSERT INTO @Resultados(LinhaComando) 
		SELECT '--Inicializa trace '  
	
	INSERT INTO @Resultados(LinhaComando) 
		SELECT '  exec sp_trace_setstatus @TraceIDout, 1 ---Inicializa trace   ' 
	
	INSERT INTO @Resultados(LinhaComando)
		SELECT '  --exec sp_trace_setstatus TRACEID, 0 ---Para o trace, você deve saber qual é o TRACEID (@TraceIDOut) para pará-lo   ' 
	
	INSERT INTO @Resultados(LinhaComando) 
		SELECT '  --exec sp_trace_setstatus TRACEID, 2 ---Remove o trace, você deve saber qual é o TRACEID (@TraceIDOut) para removê-lo  ' 
	
	SELECT LinhaComando
		FROM @Resultados 
		ORDER BY IDLinha


END