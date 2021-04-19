use SDBP12;  
go  
select 
		object_schema_name(referencing_id) as referencing_schema_name,  
		object_name(referencing_id) as referencing_entity_name,   
		b.[type_desc] as referencing_desciption,   
		coalesce(col_name(referencing_id, referenced_minor_id), '(n/a)') as referenced_minor_id,   
		referencing_class_desc, referenced_class_desc,  
		referenced_server_name, referenced_database_name, referenced_schema_name,  
		referenced_entity_name,   
		coalesce(col_name(referencing_id, referenced_minor_id), '(n/a)') as referenced_column_name,  
		is_caller_dependent, is_ambiguous  
	from sys.sql_expression_dependencies as a  
		join sys.objects as b on a.referencing_id = b.[object_id]
	where a.referencing_id = object_id(N'DCV900')