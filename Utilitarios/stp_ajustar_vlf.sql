-- Cria a procedure stp_ajustar_vlf
USE MSDB
GO
IF(EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'stp_ajustar_vlf'))
DROP PROCEDURE stp_ajustar_vlf
GO
CREATE PROCEDURE stp_ajustar_vlf
(
	@IDCONTROLE		INT = NULL,
	@TARGETSIZEMB	INT = NULL -- Tamanho que deseja ajustar, caso não queria usar tamanho padrão
)
AS
BEGIN

	DECLARE @IDMax			SMALLINT = NULL
	DECLARE @MudaTamanho	BIT = 0
	DECLARE @Contador		SMALLINT = 1	-- Contador para o loop nas bases de dados
	DECLARE @DBName			VARCHAR(100)	-- Nome do banco que estará sendo verificado
	DECLARE @LogName		VARCHAR(100)	-- Nome lógico do arquivo de log
	DECLARE @Msg			VARCHAR(100)	-- Retorno de conclusão com sucesso após cada base ser verificada
	DECLARE @Sql			VARCHAR(MAX)	-- Construção dinâmica do comando para adequação dos VLFs
	DECLARE @Target_SizeMB	INT				-- Tamanho final (ideal) do arquivo de log
	DECLARE @Cur_SizeMB		INT = 0			-- Tamanho atual do arquivo de log durante a execução do growth
	DECLARE @Iter_SizeMB	SMALLINT		-- Tamanho do crescimento a cada loop (esta variável determina o tamanho de cada VLF individualmente) 

	-- Verificação se é para executar este procedimento para todas as bases de dados, ou apenas para a base de dados setada (ID)
	If(@IDCONTROLE IS NOT NULL)
	Begin
		Set @Contador = @IDCONTROLE
		Set @IDMax = @IDCONTROLE

		If(@TARGETSIZEMB IS NOT NULL)
			Set @MudaTamanho = 1

	End
	Else
	Begin
		SELECT @IDMax= MAX(ID) FROM tbControleVLF
	End
		

	--Executa um loop em todas as bases de dados da instância atribuindo as variáveis
	While (@Contador <= @IDMax)
	BEGIN

		SELECT 
				@DBName = DatabaseName,
				@LogName = LogFileName,
				@Target_SizeMB = 
					CASE
						WHEN @MudaTamanho = 1 THEN @TARGETSIZEMB
						ELSE TargetLogFileSize_MB
					END,
				@Iter_SizeMB = 4096,  -- Defina aqui o tamanho do crescimento a cada iteração (2048MB = 128MB/VLF  |  4096MB = 256MB/VLF  | 8192MB = 512MB/VLF)
				@Cur_SizeMB = 0,
				-- Caso o Recovery model seja full, realiza um bakcup de log e em seguida um shrinkfile, caso contrário, apenas o shrink file
				-- Monta a query dinamica com base no modelo de recuperação do banco | Substitutua o texto abaixo entre comentários /* */ pela sua rotina de backup de log
				@Sql =	CASE RecoveryModelDesc
							WHEN 'SIMPLE' THEN 'USE [' +@DBName+ ']; DBCC SHRINKFILE(2, EMPTYFILE);' + CHAR(10) + 'USE [' + @DBName + ']; DBCC SHRINKFILE(2,EMPTYFILE);'
							ELSE 'USE MASTER; EXEC msdb..sp_backup_manual ''LOG'', ''DIARIO'', ''' + @DBName + ''';' + CHAR(10) + 'USE ['  + @DBName + ']; DBCC SHRINKFILE(2,EMPTYFILE);' + CHAR(10)+'USE MASTER; EXEC msdb..sp_backup_manual ''LOG'', ''DIARIO'', '''+@DBName+''';' + CHAR(10) + 'USE ['+@DBName + '] DBCC SHRINKFILE(2,EMPTYFILE); '
						END 
			FROM tbControleVLF F
				JOIN sys.databases D ON F.DatabaseName = D.[name]
			WHERE ID = @Contador
				AND D.is_read_only = 0
				AND D.user_access = 0

		RAISERROR (@Sql, 0, 1) WITH NOWAIT;
		--	EXEC(@Sql)
		
		-- Exibe o valor atual do tamanho do arquivo, bem como o tamanho alvo para o mesmo.
		--PRINT 'VALOR ATUAL: '+CAST(@Cur_SizeMB AS VARCHAR(5))
		--PRINT 'VALOR ALVO: '+CAST(@Target_SizeMB AS VARCHAR(5))
		
		-- Executa um loop em cada uma das bases incrementando pelo tamanho do @Iter_SizeMB até atingir o @Target_SizeMB
		WHile (@Cur_SizeMB < @Target_SizeMB)
		Begin

			Set @Cur_SizeMB = @Cur_SizeMB + @Iter_SizeMB
			Set @Sql = 'USE master; ALTER DATABASE [' + @DBName + '] MODIFY FILE (NAME = ''' + @LogName + ''', SIZE = ' + CAST(@Cur_SizeMB AS VARCHAR(6)) + 
					   'MB, FILEGROWTH = ' + CAST(@Iter_SizeMB AS VARCHAR(6)) + 'MB);'
			--PRINT @DBName + ': '+ CAST(@Cur_SizeMB AS VARCHAR(30))
			
			RAISERROR (@Sql, 0, 1) WITH NOWAIT;
			--EXEC(@Sql)
		End
		
		-- Ajusta o tamanho para o tamanho ideal, de acordo com o recomendado na tabela tbControleVLF		
		Set @Sql = 'USE [' +@DBName+ ']; DBCC SHRINKFILE(2 ,' + CAST(@Target_SizeMB AS VARCHAR(6)) + ');' + CHAR(10) --+  'USE [' +@DBName+ ']; DBCC SHRINKFILE(2, ' + CAST(@Target_SizeMB AS VARCHAR(6)) + ');'
		
		RAISERROR (@Sql, 0, 1) WITH NOWAIT;
		--EXEC (@Sql)

		Set @Sql = ''
		Set @Cur_SizeMB = 0
		Set @Contador = @Contador + 1

		RAISERROR (@Msg,0,1) WITH NOWAIT

	END
END
GO
--EXEC STP_AJUSTARVLF 3, 42000