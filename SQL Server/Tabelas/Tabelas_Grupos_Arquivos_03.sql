use SDBP12
go
begin

	select 
			object_name(i.[object_id]) as [objectname],
			i.[index_id] as [indexid],
			i.[name] as [indexname],
			i.[type_desc] as [indextype],
			i.data_space_id as [databasespaceid],
			f.[name] as [filegroup],
			d.physical_name as [databasefilename]
	from sys.indexes i
		join sys.filegroups f on f.data_space_id = i.data_space_id
		join sys.database_files d on f.data_space_id = d.data_space_id
		join sys.data_spaces s on f.data_space_id = s.data_space_id
	where objectproperty(i.[object_id], 'isusertable') = 1
		and f.[name] = 'AUDITTRAIL'
		and i.[type_desc] <> 'HEAP'
	order by object_name(i.[object_id]), f.[name], i.data_space_id

end