USE SDBP12
GO

set nocount on
set quoted_identifier off
set ansi_warnings off

if(object_id(N'tempdb..#t') is not null)
	drop table #t

;with refitems as
(
	select	isnull(referencing_id, o.[object_id]) as referencing_id,
			db_name(db_id()) as referencing_database_name,
			object_schema_name(isnull(referencing_id, o.[object_id])) as referencing_schema_name,
            object_name(isnull(referencing_id, o.[object_id])) as referencing_entity_name,
            o.[type_desc] as referencing_desciption,
            coalesce(col_name(referencing_id, referencing_minor_id), '(n/a)') as referencing_minor_id,
            referencing_class_desc,
            referenced_class_desc,
            referenced_database_name,
            referenced_schema_name,
            referenced_entity_name,
            coalesce(col_name(referenced_id, referenced_minor_id), '(n/a)') as referenced_column_name,
            isnull(r.[type_desc], referenced_class_desc) as referenced_desciption,
            is_caller_dependent, 
			is_ambiguous 
		from sys.sql_expression_dependencies as d
			full outer join sys.objects as o on d.referenced_id = o.[object_id]
			left outer join sys.objects as r on object_id(d.referenced_entity_name) = r.[object_id]
		where lower(o.[type_desc]) in ('sql_stored_procedure', 'view', 'sql_scalar_function', 'sql_inline_table_valued_function', 'sql_trigger')
)
select	
		referencing_id,
		referencing_database_name,
		referencing_schema_name,
		referencing_entity_name,
		referencing_desciption, null as numcodelines, 
		count(distinct isnull(referenced_database_name + '.', '') + isnull(referenced_schema_name + '.', '') + referenced_entity_name) as numreferencedobjects 
	into #t 
	from refitems 
	group by referencing_id, referencing_database_name, referencing_schema_name, referencing_entity_name, referencing_desciption

declare @i as int 
declare @n as varchar(128)
declare @c int 
declare @txt table
( 
	txt varchar(max) 
) 

While(EXISTS(SELECT 1 FROM   #t WHERE  NumCodeLines IS NULL))
Begin

	SELECT TOP 1 @i = referencing_id, @n = IsNull(referencing_database_name + '.', '') + IsNull(referencing_schema_name + '.', '') + referencing_entity_name
		FROM #t 
		WHERE NumCodeLines IS NULL 

	INSERT INTO @Txt(Txt) 
		EXEC sp_helptext @n 

	SELECT @c = COUNT(*) FROM @Txt
      
	UPDATE #t 
		SET NumCodeLines = @c 
		WHERE referencing_id = @i

	DELETE FROM @Txt 

End

;WITH SPSummary (DatabaseName, SchemaName, ObjectName, ObjectType, NumberOfCodeLines, NumberOfReferencedObjects, NumberOfParameters) AS(
	SELECT	T1.referencing_database_name, T1.referencing_schema_name, T1.referencing_entity_name, T1.referencing_desciption, 
			T1.NumCodeLines, T1.NumReferencedObjects, Count(C.[name]) AS NumParameters 
		FROM #t AS T1
			LEFT OUTER JOIN sys.syscolumns AS C ON T1.referencing_id = C.id
		GROUP BY T1.referencing_database_name, T1.referencing_schema_name, T1.referencing_entity_name, T1.referencing_desciption, T1.NumCodeLines, T1.NumReferencedObjects
)
SELECT DISTINCT DatabaseName, SchemaName, ObjectName, ObjectType, NumberOfCodeLines, NumberOfReferencedObjects, NumberOfParameters,                
		CASE 
			WHEN NumberOfCodeLines * NumberOfReferencedObjects * NumberOfParameters < 5000 THEN 'SIMPLE'
			WHEN NumberOfCodeLines * NumberOfReferencedObjects * NumberOfParameters < 10000 THEN 'MEDIUM'
			ELSE 'COMPLEX'
		END AS Complexity
	FROM SPSummary 
	ORDER BY DatabaseName, SchemaName, ObjectType, ObjectName

If(Object_ID(N'tempdb..#t') IS NOT NULL)
	DROP TABLE #t