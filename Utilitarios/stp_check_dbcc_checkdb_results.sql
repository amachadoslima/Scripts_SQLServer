USE msdb 
GO
IF(EXISTS(SELECT TOP 1 NULL FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'sp_check_dbcc_checkdb_results'))
	DROP PROCEDURE sp_check_dbcc_checkdb_results
GO
CREATE PROCEDURE sp_check_dbcc_checkdb_results
WITH ENCRYPTION 
AS
BEGIN

	SET NOCOUNT ON
	SET DATEFORMAT YMD

	DECLARE @FlashBack DATETIME
	Set @FlashBack = NULL

	If(@FlashBack IS NULL AND NOT EXISTS(SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DBA'))
	Begin
		CREATE TABLE dbo.DBA
		(
			LASTDATE DATETIME
		)
		INSERT INTO DBA (LASTDATE) VALUES (GETDATE());
	End

	DECLARE @LastDate DATETIME 

	IF (@FlashBack IS NOT NULL)
		SET @LastDate = @FlashBack;
	ELSE
		SELECT @LastDate = LASTDATE FROM master.dbo.DBA;
   
	If(Object_ID(N'tempdb..#tmpLogRes') IS NOT NULL)
		DROP TABLE #tmpLogRes;
   
	CREATE TABLE #tmpLogRes
	(
		LogDate datetime,
		ProcessInfo varchar(100),
		TextLine varchar(500)
	)

	INSERT #tmpLogRes EXEC sp_readerrorlog 0, 1, 'DBCC CHECKDB'

	;WITH CTE AS (
		SELECT 
				LogDate,
				dbo.fn_GetStringBetween(TextLine ,'(',')' ) AS CHECKED_DB,
				dbo.fn_GetStringBetween(TextLine ,'found','errors' ) AS ERRORS_FOUND,
				dbo.fn_GetStringBetween(TextLine ,'repaired','errors.' ) AS ERRORS_REPAIRED
			FROM #tmpLogRes
			WHERE TextLine LIKE '%DBCC CHECKDB%' 
				AND LogDate > Convert(VARCHAR(10), @LastDate, 121)
	)
	SELECT *
		FROM CTE
		WHERE ERRORS_FOUND > 0 OR ERRORS_REPAIRED > 0

	If(Object_ID(N'tempdb..##tmpLogRes') IS NOT NULL)
		DROP TABLE #tmpLogRes;
  
END