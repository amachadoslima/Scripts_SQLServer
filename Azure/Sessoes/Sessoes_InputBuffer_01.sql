SET NOCOUNT ON

DECLARE @OSQL TABLE
(
	SPID			INT,
	DB				VARCHAR(100),
	--PID				INT,
	LoginName		VARCHAR(MAX),
	IniExec			DATETIME,
	SQLText			VARCHAR(MAX),
	OutputBuffer	VARCHAR(MAX),
	KillCMD			VARCHAR(MAX)
)
	
DECLARE @DB			NVARCHAR(100)
DECLARE @SPID		NVARCHAR(50)
DECLARE @PID		NVARCHAR(50)
DECLARE @LoginName	NVARCHAR(100)
DECLARE @IniExec	DATETIME

BEGIN TRY

	DECLARE SPID CURSOR FOR 
		SELECT S.Session_ID, DB_Name(R.Database_ID), S.Login_Name, R.Start_Time, S.Host_Process_ID
			FROM sys.dm_exec_sessions S
				JOIN sys.dm_exec_requests R on S.Session_ID = R.Session_ID
			WHERE S.Session_ID > 50	and S.Session_ID <> @@SPID
				

	OPEN SPID
	FETCH NEXT FROM SPID INTO @SPID, @DB, @LoginName, @IniExec, @PID

		While(@@FETCH_STATUS = 0)
		Begin
		
			INSERT INTO @OSQL (SPID, DB, LoginName, IniExec)--, pid)
				SELECT @SPID, @DB, @LoginName, @IniExec--, @PID
		
			DECLARE @AUX TABLE
			(
				eventtype NVARCHAR(max),
				parameters NVARCHAR(max),
				eventinfo NVARCHAR(max)
			)
		
			INSERT INTO @AUX
				EXEC ('DBCC INPUTBUFFER(' + @SPID + ') WITH NO_INFOMSGS')
			
			UPDATE @OSQL
				SET SQLText = (SELECT RTrim(LTrim(Replace(EventInfo, (CHAR(13) + CHAR(10)), ''))) FROM @AUX),
					OutputBuffer = 'DBCC OUTPUTBUFFER (' + @SPID + ');',
					KillCMD = 'KILL ' + @SPID + ';'
				WHERE SPID = @SPID

			DELETE FROM @AUX
			FETCH NEXT FROM SPID INTO @SPID, @DB, @LoginName, @IniExec, @PID

		END

	CLOSE SPID
	DEALLOCATE SPID


	SELECT * FROM @OSQL WHERE SQLText IS NOT NULL ORDER BY SPID DESC

END TRY
BEGIN CATCH
	SELECT ERROR_LINE() AS ERR_LINE, ERROR_NUMBER() AS ERR_NUM, ERROR_MESSAGE() AS ERR_MSG
	CLOSE SPID
	DEALLOCATE SPID
END CATCH