USE msdb
GO

BEGIN

	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF

	DECLARE @StepID INT
	DECLARE @StepName VARCHAR(200)
	DECLARE @JobName VARCHAR(200) = 'Sigero - Followup - Processar Pesquisa'
	DECLARE @Commands TABLE
	(
		StepID INT,
		StepName VARCHAR(300),
		Command VARCHAR(MAX)
	)

	INSERT INTO @Commands
		SELECT step_id, step_name, command 
			FROM sysjobs J
				JOIN sysjobsteps S ON J.job_id = S.job_id
			WHERE [name] = @JobName

	BEGIN TRY
		
		DECLARE @SPID INT
		DECLARE @SQLText VARCHAR(MAX)

		DECLARE @Requests TABLE
		(
			SPID INT,
			SQLText VARCHAR(MAX)
		)

		DECLARE curReqs CURSOR FOR
			SELECT S.session_id
				FROM sys.dm_exec_sessions S
					JOIN sys.dm_exec_requests R ON S.session_id = R.session_id
				WHERE S.session_id > 50	AND S.session_id <> @@SPID

		OPEN curReqs
		FETCH NEXT FROM curReqs INTO @SPID

		While(@@FETCH_STATUS = 0)
		Begin
			
			INSERT INTO @Requests(SPID) VALUES(@SPID)
		
			DECLARE @InputBuffer TABLE
			(
				EventType NVARCHAR(MAX),
				[Parameters] NVARCHAR(MAX),
				EventInfo NVARCHAR(MAX)
			)

			INSERT INTO @InputBuffer
				EXEC ('DBCC INPUTBUFFER(' + @SPID + ') WITH NO_INFOMSGS')

			UPDATE @Requests
				SET SQLText = (SELECT RTrim(LTrim(Replace(EventInfo, (CHAR(13) + CHAR(10)), ''))) FROM @InputBuffer)
				WHERE SPID = @SPID

			DELETE FROM @InputBuffer
			FETCH NEXT FROM curReqs INTO @SPID
		End

		CLOSE curReqs
		DEALLOCATE curReqs

		SELECT @StepID = A.StepID, @StepName = A.StepName
			FROM @Commands A 
				JOIN @Requests B ON A.Command = B.SQLText 

		If(@StepID IS NOT NULL)
		Begin
			DECLARE @Coalasce VARCHAR(MAX)
			SELECT 'PASSO ' + Cast(@StepID AS VARCHAR) + ' >> ' + @StepName AS [Status],
				  LTrim((
					SELECT Steps = Stuff((
						SELECT ', ' + StepName
							FROM @Commands
							WHERE StepID < @StepID
							FOR XML PATH('')
						), 1, 1, '')
				  )) AS PassosExecutados,
				  LTrim((
					SELECT Steps = Stuff((
						SELECT ', ' + StepName
							FROM @Commands
							WHERE StepID > @StepID
							FOR XML PATH('')
						), 1, 1, '')
				  )) AS PassosSeremExecutados
		End

	END TRY
	BEGIN CATCH
		SELECT ERROR_NUMBER() AS ERR_NUM, ERROR_MESSAGE() AS ERR_MSG
		RETURN
	END CATCH

END
