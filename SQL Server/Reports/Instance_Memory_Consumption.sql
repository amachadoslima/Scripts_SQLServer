USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- MEMORY STATUS
BEGIN TRY

	DECLARE @Info TABLE
	(
		objecttype	VARCHAR (100) COLLATE DATABASE_DEFAULT,
		buffers		BIGINT
	)

	INSERT @Info
		EXEC('DBCC MEMORYSTATUS WITH TABLERESULTS')

	SELECT 
			0 AS row_no,
			objecttype,
			buffers AS [value],
			1 AS [state],
			1 AS msg
		FROM @Info
		WHERE objecttype IN ('Stolen','Free','Cached','Dirty','Kept','I/O','Latched','Other')
END TRY
BEGIN CATCH
	SELECT 
		-100 AS row_no,
		ERROR_NUMBER() AS objecttype,
		ERROR_SEVERITY() AS [value],
		ERROR_STATE() AS [state],
		ERROR_MESSAGE() AS msg
END CATCH
             
-- PERFMON
GO
BEGIN TRY
		SELECT  [object_name], counter_name, Convert(VARCHAR(10), cntr_value) AS cntr_value
			FROM sys.dm_os_performance_counters
			WHERE (([object_name] like '%Manager%') AND (counter_name = 'Memory Grants Pending' OR counter_name = 'Memory Grants Outstanding' ))
	UNION ALL
		SELECT  [object_name], counter_name, Convert(VARCHAR(10), cntr_value) AS cntr_value
			FROM sys.dm_os_performance_counters
		WHERE (([object_name] like '%Manager%') AND (counter_name = 'Page life expectancy' /*OR counter_name = 'Stolen pages'*/))
END TRY
BEGIN CATCH
	SELECT TOP 0 
		0 AS [object_name],
		0 AS counter_name,
		0 AS cntr_value
END CATCH
GO

-- MEMORY CLERKS
BEGIN TRY
										
	DECLARE @total_alcted_v_res_awe_s_res BIGINT

	DECLARE @Tab TABLE 
	(
		row_no		INT IDENTITY,
		[type]		NVARCHAR(128) COLLATE DATABASE_DEFAULT,
		allocated	BIGINT,
		vertual_res BIGINT,
		virtual_com BIGINT,
		awe			BIGINT,
		shared_res	BIGINT,
		shared_com	BIGINT,
		graph_type	NVARCHAR(128),
		grand_total BIGINT
	)

	SELECT 
			@total_alcted_v_res_awe_s_res = Sum(single_pages_kb + multi_pages_kb + (
				CASE 
					WHEN [type] <> 'MEMORYCLERK_SQLBUFFERPOOL' THEN virtual_memory_committed_kb ELSE 0 
				END) + shared_memory_committed_kb)
		FROM sys.dm_os_memory_clerks

	INSERT INTO @Tab
		SELECT
				[type],
				Sum(single_pages_kb + multi_pages_kb) AS allocated,
				Sum(virtual_memory_reserved_kb) AS vertual_res,
				Sum(virtual_memory_committed_kb) AS virtual_com,
				sum(awe_allocated_kb) AS awe,
				Sum(shared_memory_reserved_kb) AS shared_res,
				Sum(shared_memory_committed_kb) AS shared_com,
				CASE
					WHEN ((Sum(single_pages_kb + multi_pages_kb + (
						CASE 
							WHEN [type] <> 'MEMORYCLERK_SQLBUFFERPOOL' THEN virtual_memory_committed_kb 
							ELSE 0 
						END) + shared_memory_committed_kb)) / (@total_alcted_v_res_awe_s_res + 0.0)) >= 0.05 THEN [type]
					ELSE 'Other'
				END AS graph_type,
				(Sum(single_pages_kb + multi_pages_kb + (
					CASE 
						WHEN [type] <> 'MEMORYCLERK_SQLBUFFERPOOL' THEN virtual_memory_committed_kb 
						ELSE 0 
					END) + shared_memory_committed_kb)) AS grand_total
			FROM sys.dm_os_memory_clerks
			GROUP BY [type]
			ORDER BY (Sum(single_pages_kb + multi_pages_kb + (
				CASE 
					WHEN [type] <> 'MEMORYCLERK_SQLBUFFERPOOL' THEN virtual_memory_committed_kb 
					ELSE 0 
				END) + shared_memory_committed_kb)) DESC
	
	UPDATE @Tab 
		SET graph_type = [type] 
		WHERE row_no <= 5
	
	SELECT  * FROM @Tab

END TRY
BEGIN CATCH
	SELECT 
		-100 AS row_no,
		ERROR_NUMBER() AS [type],
		ERROR_SEVERITY() AS allocated,
		ERROR_STATE() AS vertual_res,
		ERROR_MESSAGE() AS awe,
		0 AS shared_res,
		0 AS shared_com,
		0 AS graph_type,
		0 AS grand_total
END CATCH

