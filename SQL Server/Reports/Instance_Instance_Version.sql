USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @Version	NVARCHAR(100)
DECLARE @MajorVer	TINYINT
DECLARE @MinorVer	TINYINT
DECLARE @BuildNum	SMALLINT
declare @Dec1		INT 
DECLARE @Dec2		INT
DECLARE @Dec3		INT

SELECT @Version = Convert(NVARCHAR(100), SERVERPROPERTY('ProductVersion'))
SELECT @Dec1 = CharIndex('.', @Version)
SELECT @MajorVer = Convert(TINYINT, SubString(@Version, 1, @Dec1 - 1));

SELECT 
	@MajorVer As major_version,
	NULL AS minor_version,
	NULL AS build_number,
	Convert(NVARCHAR(128), SERVERPROPERTY('MachineName')) +	
		CASE 
			WHEN Convert(NVARCHAR(128), SERVERPROPERTY('InstanceName')) IS NOT NULL THEN N'\' + Convert(NVARCHAR(128), SERVERPROPERTY('InstanceName'))
			ELSE N''
		END AS ServerInstance,
	@Version AS ProductVersion,
	SERVERPROPERTY('ProductLevel') AS ProductLevel,
	SERVERPROPERTY('Edition') AS Edition

/*
If Not (@MajorVer >= 10)
Begin
	RAISERROR('This server does not meet the requirements (SQL 2008 or later) for running the Performance Dashboard Reports.  This server is running version %s', 18, 1, @Version)
End
*/