USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

	DECLARE @Enable TINYINT

	SELECT @Enable = Convert(TINYINT, value_in_use) 
		FROM sys.configurations 
		WHERE [name] = 'default trace enabled'

	If(@Enable = 1) -- default trace
	Begin

		DECLARE @D1					DATETIME
		DECLARE @Diff				INT  
		DECLARE @CurrTraceFileName	VARCHAR(500) 
		DECLARE @BaseTraceFileName	VARCHAR(500) 
		DECLARE @Indx				INT 
			
		DECLARE @TempTrace TABLE 
		(
			textdata	NVARCHAR(MAX) COLLATE DATABASE_DEFAULT,
			login_name	SYSNAME COLLATE DATABASE_DEFAULT,
			start_time	DATETIME,
			event_class INT
		)
        
		SELECT @CurrTraceFileName = [path] 
			FROM sys.traces 
			WHERE is_default = 1  
        
		Set @CurrTraceFileName = Reverse(@CurrTraceFileName)
		SELECT @Indx  = PatIndex('%\%', @CurrTraceFileName) 
		Set @CurrTraceFileName = Reverse(@CurrTraceFileName)
		Set @BaseTraceFileName = Left(@CurrTraceFileName, Len(@CurrTraceFileName) - @Indx) + '\log.trc'
        
		INSERT INTO @TempTrace
			SELECT 
					TextData,
					LoginName,
					StartTime,
					EventClass 
				FROM ::fn_trace_gettable(@BaseTraceFileName, DEFAULT) 
				WHERE((EventClass = 22 AND Error = 15457) 
					OR (EventClass = 116 AND TextData LIKE '%TRACEO%(%'))
        
		SELECT @D1 = Min(start_time) FROM @TempTrace
        
		Set @Diff = DateDiff(hh, @D1, GetDate())
		Set @Diff = @Diff / 24 

		SELECT 
				(ROW_NUMBER() OVER (ORDER BY start_time DESC)) % 2 AS l1,
				@Diff AS [difference],
				@D1 AS [date],
				CASE event_class 
					WHEN 116 THEN 'Trace Flag ' + SubString(textdata, PatIndex('%(%', textdata), Len(textdata) - PatIndex('%(%', textdata) + 1) 
					WHEN 22 THEN SubString(textdata, 58, PatIndex('%changed from%', textdata) - 60) 
				END AS config_option,
				start_time,
				login_name,
				CASE event_class 
					WHEN 116 THEN '--'
					WHEN 22 THEN SubString(SubString(textdata, PatIndex('%changed from%', textdata), Len(textdata) - PatIndex('%changed from%', textdata)),
								 PatIndex('%changed from%', SubString(textdata, PatIndex('%changed from%', textdata), Len(textdata) - PatIndex('%changed from%', textdata))) + 13,
								 PatIndex('%to%', SubString(textdata, PatIndex('%changed from%',textdata), Len(textdata) - 
								 PatIndex('%changed from%',textdata))) - PatIndex('%from%', SubString(textdata, PatIndex('%changed from%', textdata), 
								 Len(textdata) - PatIndex('%changed from%',textdata))) - 6) 
				END AS old_value,
				CASE event_class 
					WHEN 116 THEN SubString(textdata, PatIndex('%TRACE%', textdata) + 5, PatIndex('%(%',textdata) - PatIndex('%TRACE%', textdata) - 5)
					WHEN 22 THEN SubString(SubString(textdata, PatIndex('%changed from%', textdata), Len(textdata) - PatIndex('%changed from%', textdata)),
								 PatIndex('%to%', SubString(textdata, PatIndex('%changed from%', textdata), Len(textdata) - PatIndex('%changed from%', textdata))) + 3,
								 PatIndex('%. Run%', SubString(textdata, PatIndex('%changed from%', textdata), Len(textdata) - PatIndex('%changed from%', textdata))) - 
								 PatIndex('%to%',SubString(textdata, PatIndex('%changed from%',textdata), Len(textdata) - PatIndex('%changed from%', textdata))) - 3) 
				END AS new_value
			FROM @TempTrace 
			ORDER BY start_time DESC
	End
	Else
	BEGIN 
		SELECT TOP 0 
			1 AS l1, 
			1 AS [difference], 
			1 AS [date], 
			1 AS config_option,
			1 AS start_time, 
			1 AS login_name, 
			1 AS old_value, 
			1 AS new_value
	End
END TRY 
BEGIN CATCH
	SELECT
		-100  AS l1,
		ERROR_NUMBER() AS [difference],
		ERROR_SEVERITY() AS [date],
		ERROR_STATE() AS config_option,
		1 AS start_time,
		ERROR_MESSAGE() AS login_name,
		1 AS old_value,
		1 AS new_value
END CATCH