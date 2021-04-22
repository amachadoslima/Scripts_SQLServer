-- Cria a procedure stp_setup_controle_vlf
USE msdb 
GO
IF(EXISTS(SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'stp_setup_controle_vlf'))
DROP PROCEDURE stp_setup_controle_vlf
GO
CREATE PROCEDURE stp_setup_controle_vlf
AS
BEGIN
	
	IF(OBJECT_ID('tbtbControleVLF') IS NOT NULL)
		DROP TABLE tbControleVLF

	CREATE TABLE tbControleVLF
	(
			ID						INT IDENTITY,
			ServerName				VARCHAR(30),
			DatabaseID				SMALLINT,
			DatabaseName			VARCHAR(30),
			RecoveryModelDesc		VARCHAR(15),
			HasFullBackup			BIT,
			TargetLogFileSize_MB	NUMERIC(20, 2),
			QtdVLF					INT,
			CheckDate				DATETIME,
			LastShrinkDate			DATETIME,
			ShrinkCounter			SMALLINT DEFAULT 0,
			LogFileName				VARCHAR(50),
			PhysicalFileName		VARCHAR(300),
			FileState				VARCHAR(10)
		)

		--CRIA TABELA TEMPORÁRIA PARA COLETAR INFORMAÇÕES DO DBCC LOGINFO
		IF(OBJECT_ID('tempdb..##LogInfo') IS NOT NULL)
			DROP TABLE ##LogInfo;

		CREATE TABLE ##LogInfo
		(
			ServerName		VARCHAR(30) DEFAULT @@SERVERNAME,
			DatabaseID		SMALLINT DEFAULT DB_ID(),
			DatabaseName	VARCHAR(30) DEFAULT DB_NAME(),
			RecoveryUnitId	TINYINT,
			FileID			TINYINT,
			FileSize		BIGINT,
			StartOffset		BIGINT,
			FSeqNo			INT,
			[Status]		TINYINT,
			Parity			SMALLINT,
			CreateLSN		VARCHAR(40)
		)

		--COLETA INFORMAÇÕES DOS VLFs
		EXEC sp_msforeachdb '
		USE [?];
		IF DB_ID() > 4
		BEGIN
			INSERT INTO ##LOGINFO (FileID,FileSize,StartOffset,FSeqNo,Status,Parity,CreateLSN)
			EXEC (''DBCC LOGINFO'')
		END
		'

		--ARMAZENA AS INFORMAÇOES RELEVANTES REFERENTES AOS VLFs
		INSERT INTO tbControleVLF
		( 
			ServerName,
			DatabaseID,
			DatabaseName,
			RecoveryModelDesc,
			HasFullBackup, 
			TargetLogFileSize_MB,
			QtdVLF,
			CheckDate,
			LogFileName,
			PhysicalFileName,
			FileState
		)
		SELECT  ServerName,
				DatabaseID,
				DatabaseName,
				sd.recovery_model_desc,
				CASE 
					WHEN EXISTS (SELECT TOP 1 * FROM msdb..backupset WHERE [type] = 'D' AND [database_name] = DatabaseName) THEN 1
					ELSE 0
				END,				
				CAST(SUM(FILESIZE) / 1024. AS DEC(20, 2)) / 1024. AS TargetLogFileSize_MB,
				COUNT(1) AS QtdVLF,
				GETDATE() AS CheckDate ,
				mf.[name],
				mf.physical_name, 
				mf.state_desc
			FROM ##LogInfo li
				JOIN sys.master_files mf ON li.DatabaseID = mf.database_id
				JOIN sys.databases sd ON sd.database_id = li.databaseid AND sd.database_id = mf.database_id
			WHERE mf.[type_desc] = 'log'
				AND mf.database_id > 4
				AND mf.state_desc = 'online'
			GROUP BY ServerName, DatabaseID, DatabaseName, mf.[name], mf.physical_name, mf.state_desc	, sd.recovery_model_desc
			ORDER BY DatabaseID
		 

	--ATUALIZA O MENOR TAMANHO PARA O TAMANHO DO MENOR VLF
	UPDATE C 
		SET c.TargetLogFileSize_MB = 256
		FROM DBA.tbControleVLF c
		WHERE TargetLogFileSize_MB < 512

	SELECT * 
		FROM tbControleVLF

END