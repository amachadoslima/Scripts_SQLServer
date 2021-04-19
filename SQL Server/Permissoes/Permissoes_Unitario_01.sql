use SIGERO_ADMIN
go
select 
		dp.[name] as principal_name,
		dp.[type_desc] as principal_type_desc,
        o.[name] as [object_name],
        o.[type_desc],
        p.[permission_name],
        p.state_desc as permission_state_desc
	from sys.all_objects o
        join sys.database_permissions p on o.[object_id] = p.major_id
        left outer join sys.database_principals dp on p.grantee_principal_id = dp.principal_id
    where lower(o.[name]) = 'sp_concluirmedicao'