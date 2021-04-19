USE master
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SELECT 
			QP.query_plan,
			(total_worker_time / execution_count) AS avg_cpu,
			(total_elapsed_time / execution_count) As avg_duration,
			((total_logical_reads + total_physical_reads) / execution_count) AS avg_reads,
			execution_count,
			SubString(ST.[text], (QS.statement_start_offset / 2) + 1, ((CASE QS.statement_end_offset WHEN -1 THEN DataLength(ST.[text]) ELSE QS.statement_end_offset END - QS.statement_start_offset) / 2) + 1) AS Txt,
			(QP.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]' , 'decimal(18,4)') * execution_count) AS total_impact,
			QP.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]' , 'varchar(100)') AS [db_name],
			QP.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]' , 'varchar(100)') AS [table]
		FROM sys.dm_exec_query_stats QS
			CROSS APPLY sys.dm_exec_sql_text(QS.[sql_handle]) ST
			CROSS APPLY sys.dm_exec_query_plan(QS.[plan_handle]) QP
		WHERE QP.query_plan.exist('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan";/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex[@Database!="m"]') = 1
		ORDER BY total_impact DESC

END