EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;

IF(OBJECT_ID(N'tempdb..#Drives') IS NOT NULL)
	DROP TABLE #Drives

SET NOCOUNT ON

DECLARE @Hr INT
DECLARE @Fso INT
DECLARE @Drive CHAR(1)
DECLARE @ODrive INT
DECLARE @TotalSize VARCHAR(20) 
DECLARE @MB NUMERIC

SET @MB = 1048576

CREATE TABLE #Drives
(
	Drive CHAR(1) PRIMARY KEY, 
	FreeSpace DECIMAL(18,2) NULL,
	TotalSize DECIMAL(18,2) NULL,
	ContainsDataFiles BIT NULL DEFAULT(0)
) 

INSERT #Drives(Drive, FreeSpace) 
	EXEC master.dbo.xp_fixeddrives 

EXEC @Hr = sp_OACreate 'Scripting.FileSystemObject', @Fso OUT 

If(@Hr <> 0)
	EXEC sp_OAGetErrorInfo @Fso

DECLARE dcur CURSOR LOCAL FAST_FORWARD FOR 
	SELECT Drive 
		FROM #Drives 
		ORDER BY drive

OPEN dcur 
FETCH NEXT FROM dcur INTO @Drive

While(@@FETCH_STATUS = 0)
Begin
	EXEC @Hr = sp_OAMethod @Fso,'GetDrive', @ODrive OUT, @Drive
	If(@Hr <> 0)
		EXEC sp_OAGetErrorInfo @Fso 
	
	EXEC @Hr = sp_OAGetProperty @ODrive,'TotalSize', @TotalSize OUT 
	If(@Hr <> 0)
		EXEC sp_OAGetErrorInfo @ODrive 
		
	UPDATE #Drives SET TotalSize=@TotalSize/@MB WHERE Drive=  @Drive 
	FETCH NEXT FROM dcur INTO @Drive

End

CLOSE dcur
DEALLOCATE dcur

EXEC @Hr = sp_OADestroy @Fso 

If(@Hr <> 0) 
	EXEC sp_OAGetErrorInfo @Fso

UPDATE #Drives
	SET ContainsDataFiles = 1
	WHERE EXISTS(
		SELECT NULL
			FROM sys.master_files
			WHERE physical_name LIKE #Drives.Drive + ':\%'
	)

SELECT 
		@@SERVERNAME AS Instancia,
		Drive, 
		(TotalSize / 1024) AS 'Total(GB)', 
		(FreeSpace / 1024) AS 'Free(GB)', 
		(((FreeSpace / 1024) / (TotalSize / 1024)) * 100) AS [PercenteFree(GB)] ,
		ContainsDataFiles
	FROM #Drives
	ORDER BY Drive

IF(OBJECT_ID(N'tempdb..#Drives') IS NOT NULL)
	DROP TABLE #Drives

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ole Automation Procedures', 0;
RECONFIGURE;
/*******************************************************/