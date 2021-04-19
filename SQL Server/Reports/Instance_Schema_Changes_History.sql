USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

	DECLARE @Enable INT
	SELECT TOP 1 @Enable = Convert(INT, value_in_use) 
		FROM sys.configurations WHERE
			[name] = 'default trace enabled'

	If(@Enable = 1) --default trace is enabled
	Begin 

		DECLARE @D1					DATETIME
		DECLARE @Diff				INT
		DECLARE @CurrTraceFileName	VARCHAR(500) 
		DECLARE @BaseTraceFileName	VARCHAR(500) 
		DECLARE @Idx				int

		DECLARE @TempTrace TABLE
		(
			obj_name			NVARCHAR(256) COLLATE DATABASE_DEFAULT,
			[database_name]		NVARCHAR(256) COLLATE DATABASE_DEFAULT,
			start_time			DATETIME,
			event_class			INT,
			event_subclass		INT,
			object_type			INT,
			server_name			nvarchar(256) COLLATE DATABASE_DEFAULT,
			login_name			nvarchar(256) COLLATE DATABASE_DEFAULT,
			application_name	NVARCHAR(256) COLLATE DATABASE_DEFAULT,
			ddl_operation		NVARCHAR(40) COLLATE DATABASE_DEFAULT
		)
        
		SELECT @CurrTraceFileName = [path]
			FROM sys.traces 
			WHERE is_default = 1

		Set @CurrTraceFileName = Reverse(@CurrTraceFileName)
		SELECT @Idx  = PatIndex('%\%', @CurrTraceFileName) 
		Set @CurrTraceFileName = Reverse(@CurrTraceFileName)
		Set @BaseTraceFileName = Left(@CurrTraceFileName, Len(@CurrTraceFileName) - @Idx) + '\log.trc'

		INSERT INTO @TempTrace 
			SELECT 
					ObjectName,
					DatabaseName,
					StartTime,
					EventClass,
					EventSubClass,
					ObjectType,
					ServerName,
					LoginName,
					ApplicationName,
					'temp' 
				FROM ::fn_trace_gettable( @BaseTraceFileName, DEFAULT) 
				WHERE EventClass IN (46, 47, 164) 
					AND EventSubclass = 0 
					AND DatabaseID <> 2 

		UPDATE @TempTrace SET ddl_operation = 'CREATE' WHERE event_class = 46
		UPDATE @TempTrace SET ddl_operation = 'DROP' WHERE event_class = 47
		UPDATE @TempTrace SET ddl_operation = 'ALTER' WHERE event_class = 164

		SELECT @D1 = Min(start_time) FROM @TempTrace
		Set @Diff = DateDiff(hh, @D1, GetDate())
		Set @Diff = @Diff/24 

		SELECT  
				@Diff AS [difference],
				@D1 AS [date],
				object_type AS obj_type_desc,
				* 
			FROM @TempTrace 
			WHERE object_type NOT IN (21587)
			ORDER by start_time DESC
	End 
	Else
	Begin 
		SELECT TOP 0 
			1 AS [difference],
			1 AS [date],
			1 AS obj_type_desc,
			1 AS obj_name,
			1 AS dadabase_name,
			1 AS start_time,
			1 AS event_class,
			1 AS event_subclass,
			1 AS object_type,
			1 AS server_name,
			1 AS login_name,
			1 AS application_name,
			1 AS ddl_operation 
	End
END TRY
BEGIN CATCH
	SELECT 
		-100 AS [difference],
		ERROR_NUMBER() AS [date],
		ERROR_SEVERITY() AS obj_type_desc,
		ERROR_STATE() AS obj_name,
		ERROR_MESSAGE() AS [database_name],
		1 AS start_time,
		1 AS event_class,
		1 AS event_subclass,
		1 AS object_type,
		1 AS server_name,
		1 AS login_name,
		1 AS application_name,
		1 AS ddl_operation 
end catch