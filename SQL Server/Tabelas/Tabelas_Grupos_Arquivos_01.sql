use SDBP12
go
select distinct
		o.[name],
		o.[type],
		f.[name]
	from sys.indexes i
		join sys.filegroups f on i.data_space_id = f.data_space_id
		join sys.all_objects o on i.[object_id] = o.[object_id]
	where i.data_space_id = f.data_space_id
		and o.[type] = 'u'