USE [master]
GO

SET NOCOUNT ON
SET QUOTED_IDENTIFIER OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
		d.database_id, 
		d.[object_id], 
		d.index_handle, 
		d.equality_columns, 
		d.inequality_columns, 
		d.included_columns, 
		d.[statement] AS fully_qualified_object,
		gs.*, 
		Floor((Convert(NUMERIC(19,3), gs.user_seeks) + Convert(NUMERIC(19,3), gs.user_scans)) *	
				Convert(NUMERIC(19,3), gs.avg_total_user_cost) * Convert(NUMERIC(19,3), gs.avg_user_impact)) AS Score
	FROM sys.dm_db_missing_index_groups g
		JOIN sys.dm_db_missing_index_group_stats gs ON gs.group_handle = g.index_group_handle
		JOIN sys.dm_db_missing_index_details d ON g.index_handle = d.index_handle
	WHERE d.database_id = IsNull(NULL, d.database_id) 
		AND d.[object_id] = IsNull(NULL, d.[object_id])