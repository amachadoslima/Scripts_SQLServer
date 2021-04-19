USE rockingtags_LojasRenner
GO
SELECT  
		QUOTENAME(SCHEMA_NAME(OB.[schema_id])) + '.' + QUOTENAME(OBJECT_NAME(PS.[object_id])) AS table_name,
		PS.index_id,
		PS.index_type_desc,
		PS.index_level,
		Convert(DECIMAL(10,5), PS.avg_fragmentation_in_percent) AS avg_fragmentation_in_percent,
		Convert(DECIMAL(10,5), PS.avg_page_space_used_in_percent) AS avg_page_space_used_in_percent,
		PS.page_count
	FROM sys.dm_db_index_physical_stats(DB_ID(DB_NAME()), NULL, NULL, NULL , 'SAMPLED') PS
		JOIN sys.objects OB 
			ON PS.[object_id] = OB.[object_id]