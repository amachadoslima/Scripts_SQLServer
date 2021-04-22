USE DBATools
GO
IF(EXISTS(SELECT 1 FROM sys.objects WHERE name = N'stp_monitoramento_locks' AND type = N'P'))
DROP PROCEDURE stp_monitoramento_locks
GO
CREATE PROCEDURE [dbo].[stp_monitoramento_locks]
AS 
BEGIN
    
    IF (OBJECT_ID('dbo.Alerta') IS NULL)
    BEGIN

        CREATE TABLE dbo.Alerta (
            IDAlerta INT NOT NULL IDENTITY(1, 1),
            NmAlerta VARCHAR(200) NULL,
            DsMensagem VARCHAR(2000) NULL,
            FlTipo TINYINT NULL,
            DtAlerta DATETIME NULL DEFAULT (GETDATE())
        ) WITH (DATA_COMPRESSION = PAGE)

        ALTER TABLE dbo.Alerta ADD CONSTRAINT PK_Alerta PRIMARY KEY CLUSTERED (IDAlerta) WITH (DATA_COMPRESSION = PAGE)

    END


    IF (OBJECT_ID('tempdb..##Monitoramento_Locks') IS NOT NULL) 
		DROP TABLE ##Monitoramento_Locks

    CREATE TABLE ##Monitoramento_Locks
    (
        [nested_level] INT NULL,
        [session_id] INT NOT NULL,
        [login_name] NVARCHAR(128) NOT NULL,
        [host_name] NVARCHAR(128),
        [program_name] NVARCHAR(128),
        [wait_info] NVARCHAR(128),
        [wait_time_ms] BIGINT,
        [blocking_session_id] INT,
        [blocked_session_count] INT,
        [open_transaction_count] INT NOT NULL
    )

    INSERT INTO ##Monitoramento_Locks
    SELECT
        NULL AS nested_level,
        A.session_id AS session_id,
        A.login_name,
        A.[host_name],
        (CASE WHEN D.name IS NOT NULL THEN 'SQLAgent - TSQL Job (' + D.[name] + ' - ' + SUBSTRING(A.[program_name], 67, LEN(A.[program_name]) - 67) +  ')' ELSE A.[program_name] END) AS [program_name],
        '(' + CAST(COALESCE(E.wait_duration_ms, B.wait_time) AS VARCHAR(20)) + 'ms)' + COALESCE(E.wait_type, B.wait_type) + COALESCE((CASE 
            WHEN COALESCE(E.wait_type, B.wait_type) LIKE 'PAGE%LATCH%' THEN ':' + DB_NAME(LEFT(E.resource_description, CHARINDEX(':', E.resource_description) - 1)) + ':' + SUBSTRING(E.resource_description, CHARINDEX(':', E.resource_description) + 1, 999)
            WHEN COALESCE(E.wait_type, B.wait_type) = 'OLEDB' THEN '[' + REPLACE(REPLACE(E.resource_description, ' (SPID=', ':'), ')', '') + ']'
            ELSE ''
        END), '') AS wait_info,
        COALESCE(E.wait_duration_ms, B.wait_time) AS wait_time_ms,
        NULLIF(B.blocking_session_id, 0) AS blocking_session_id,
        COALESCE(G.blocked_session_count, 0) AS blocked_session_count,
        A.open_transaction_count
    FROM sys.dm_exec_sessions AS A WITH (NOLOCK)
			LEFT JOIN sys.dm_exec_requests AS B WITH (NOLOCK) 
				ON A.session_id = B.session_id
			LEFT JOIN msdb.dbo.sysjobs AS D 
				ON RIGHT(D.job_id, 10) = RIGHT(SUBSTRING(A.[program_name], 30, 34), 10)
			LEFT JOIN (
				SELECT
					session_id, 
					wait_type,
					wait_duration_ms,
					resource_description,
					ROW_NUMBER() OVER(PARTITION BY session_id ORDER BY (CASE WHEN wait_type LIKE 'PAGE%LATCH%' THEN 0 ELSE 1 END), wait_duration_ms) AS Ranking
				FROM sys.dm_os_waiting_tasks
			) E 
				ON A.session_id = E.session_id AND E.Ranking = 1
			LEFT JOIN (
				SELECT
					blocking_session_id,
					COUNT(*) AS blocked_session_count
				FROM sys.dm_exec_requests
				WHERE blocking_session_id != 0
				GROUP BY blocking_session_id
			) G 
				ON A.session_id = G.blocking_session_id
	WHERE A.session_id > 50
		AND A.session_id <> @@SPID
		AND (NULLIF(B.blocking_session_id, 0) IS NOT NULL OR COALESCE(G.blocked_session_count, 0) > 0)


    ------------------------------------------------
    -- Gera o nível dos locks
    ------------------------------------------------

    UPDATE ##Monitoramento_Locks
    SET nested_level = 1
    WHERE blocking_session_id IS NULL


    DECLARE @Contador INT = 2

    WHILE((SELECT COUNT(*) FROM ##Monitoramento_Locks WHERE nested_level IS NULL) > 0 AND @Contador < 50)
    BEGIN
        

        UPDATE A
        SET A.nested_level = @Contador
        FROM ##Monitoramento_Locks A
            JOIN ##Monitoramento_Locks B 
				ON A.blocking_session_id = B.session_id
        WHERE  A.nested_level IS NULL
            AND B.nested_level = (@Contador - 1)

        SET @Contador += 1


    END


    UPDATE ##Monitoramento_Locks
    SET nested_level = @Contador
    WHERE nested_level IS NULL


    CREATE CLUSTERED INDEX SK01 ON ##Monitoramento_Locks(nested_level, blocked_session_count DESC, wait_time_ms DESC)


    DECLARE @QtSessoesBloqueadas INT
    DECLARE @QtSessoesBloqueadasTotal INT
    DECLARE @FlUltimoStatus INT
    DECLARE @DtUltimoAlerta DATETIME
    DECLARE @DsMensagem VARCHAR(MAX)
    DECLARE @DsAssunto VARCHAR(100)
    -- Configurações do monitoramento
    DECLARE @QtMinutosLock INT = 3
    DECLARE @QtMinutosEntreAlertas INT = 30
	DECLARE @DsEmailDestinatario VARCHAR(MAX) = 'destinatario@seudominio.com.br'
    

    SELECT @QtSessoesBloqueadas = COUNT(*)
    FROM ##Monitoramento_Locks
    WHERE wait_time_ms > (60000 * @QtMinutosLock)
        AND blocking_session_id IS NOT NULL

    SELECT @QtSessoesBloqueadasTotal = COUNT(*)
    FROM ##Monitoramento_Locks
    WHERE blocking_session_id IS NOT NULL


    SELECT 
        @FlUltimoStatus = ISNULL(A.FlTipo, 0),
        @DtUltimoAlerta = ISNULL(A.DtAlerta, '1900-01-01')
    FROM dbo.Alerta A WITH(NOLOCK)
        JOIN
        (
            SELECT MAX(IDAlerta) AS IDAlerta
            FROM dbo.Alerta WITH(NOLOCK)
            WHERE NmAlerta = 'Block'
        ) B 
			ON A.IDAlerta = B.IDAlerta


    SELECT
        @FlUltimoStatus = ISNULL(@FlUltimoStatus, 0),
        @DtUltimoAlerta = ISNULL(@DtUltimoAlerta, '1900-01-01')


    
    ------------------------------------
    -- Envia o CLEAR
    ------------------------------------

    If(@FlUltimoStatus = 1 AND @QtSessoesBloqueadas = 0)
    Begin
    
        SELECT 
            @DsMensagem = CONCAT('CLEAR: Não existem mais sessões em lock na instância ', @@SERVERNAME),
            @DsAssunto = 'CLEAR - [' + @@SERVERNAME + '] - Locks na instância'
        

        INSERT INTO dbo.Alerta
        (
            NmAlerta,
            DsMensagem,
            FlTipo,
            DtAlerta
        )
        SELECT
            'Block',
            @DsMensagem,
            0,
            GETDATE()
        
        -- Envia alerta por e-mail
        -- https://www.dirceuresende.com/blog/como-habilitar-enviar-monitorar-emails-pelo-sql-server-sp_send_dbmail/
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ProfileEnvioEmail',
            @recipients = @DsEmailDestinatario,
            @subject = @DsAssunto,
            @body = @DsMensagem,
            @body_format = 'html',
            @from_address = 'remetente@seudominio.com.br'
        

    End


    ------------------------------------
    -- Envia o alerta
    ------------------------------------

    If(@QtSessoesBloqueadas > 0 AND (@FlUltimoStatus = 0 OR DATEDIFF(MINUTE, @DtUltimoAlerta, GETDATE()) >= @QtMinutosEntreAlertas))
    Begin


        SELECT 
            @DsMensagem = CONCAT('ALERTA: Existe', 
				(
					CASE 
						WHEN @QtSessoesBloqueadas > 1 THEN 'm' 
						ELSE '' 
				END), ' ', CAST(@QtSessoesBloqueadas AS VARCHAR(10)), ' ', 
				(
					CASE 
						WHEN @QtSessoesBloqueadas > 1 THEN 'sessões' 
						ELSE 'sessão' 
				END), ' em lock na instância ', @@SERVERNAME, ' há mais de ', CAST(@QtMinutosLock AS VARCHAR(10)), ' minutos e ', CAST(@QtSessoesBloqueadasTotal AS VARCHAR(10)), ' ', 
				(
					CASE 
						WHEN @QtSessoesBloqueadasTotal > 1 THEN 'sessões' 
						ELSE 'sessão' 
				END), ' em lock no total'),
            @DsAssunto = 'ALERTA - [' + @@SERVERNAME + '] - Locks na instância'

        
        INSERT INTO dbo.Alerta
        (
            NmAlerta,
            DsMensagem,
            FlTipo,
            DtAlerta
        )
        SELECT
            'Block',
            @DsMensagem,
            1,
            GETDATE()


        -- https://www.dirceuresende.com/blog/como-exportar-dados-de-uma-tabela-do-sql-server-para-html/
        DECLARE @HTML VARCHAR(MAX)
        
        EXEC dbo.stpExporta_Tabela_HTML_Output
            @Ds_Tabela = '##Monitoramento_Locks', -- varchar(max)
            @Fl_Aplica_Estilo_Padrao = 1, -- bit
            @Ds_Saida = @HTML OUTPUT -- varchar(max)


        SET @DsMensagem += '<br><br>' + @HTML

        -- Envia alerta por e-mail
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'ProfileEnvioEmail',
            @recipients = @DsEmailDestinatario,
            @subject = @DsAssunto,
            @body = @DsMensagem,
            @body_format = 'html',
            @from_address = 'remetente@seudominio.com.br'

    
    End


END